local DataStoreService = game:GetService("DataStoreService") 
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ProductReceipts = DataStoreService:GetDataStore("Product_Receipts")
local Donated = DataStoreService:GetOrderedDataStore("Donated")

local Configuration = ReplicatedStorage.Config
local deathScreenRemote = ReplicatedStorage.Events.DeathScreen

local reviveID = 3418112107
local reviveLocations = workspace.ReviveLocations

local productFunctions = {}


productFunctions[reviveID] = function(receipt, player : Player)
	local locationName = Configuration:GetAttribute("ReviveLocation")
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		if locationName == "AttackRoom" then
			local sword = game.ServerStorage.AttackSequence.Weapon:Clone()
			sword.Parent = player.Backpack

		elseif locationName == "Obby" then
			player:SetAttribute("ObbyImmunity", true)
			-- they could die and respawn at end of obby don't want them dying due to not being
			-- detected by failed or finished obby
		end

		hrp:PivotTo(reviveLocations[locationName].CFrame)
		deathScreenRemote:FireClient(player, "PURCHASED")
		player:SetAttribute("Alive", true)
		return true
	end
end

local function updateDonatedData(playerId, amount)
	local ATTEMPT_LIMIT = 5
	local ATTEMPT_WAIT = 0.5
	local ATTEMPT = 0

	local success, result

	repeat
		success, result = pcall(function()
			Donated:UpdateAsync(playerId, function(value)
				if value == nil then value = 0 end
				value += amount
				return value
			end)
		end)
		ATTEMPT += 1	
		if not success then task.wait(ATTEMPT * ATTEMPT_WAIT) end
		
	until success or ATTEMPT >= ATTEMPT_LIMIT 

	if not success then 
		warn("Failed to update donated data for player id :" .. playerId .. ", amount :" .. amount)
	end
end
	
local function processReceipt(receiptInfo)
	local purchaseId = receiptInfo.PurchaseId
	local productId = receiptInfo.ProductId
	local playerId = receiptInfo.PlayerId
	local price = tonumber(receiptInfo.CurrencySpent)
	local playerProductKey = playerId .. "_" .. purchaseId

	local success, result = pcall(ProductReceipts.UpdateAsync, ProductReceipts, playerProductKey, function(isPurchased)
		if isPurchased then return true end

		local player = Players:GetPlayerByUserId(playerId)
		if not player then return nil end

		local handler = productFunctions[productId] 
		if not handler then
			warn("No handler function for product :" .. productId)
			return nil
		end

		local handlerSuccess, handlerResult = pcall(handler, receiptInfo, player)
		if not handlerSuccess then
			warn(
				"Purchase handler failed for " .. player.Name .. "for product ID: " .. productId .. handlerResult
			)
			return nil
		end

		local didHandlerGrantPurchase = handlerResult == true 
		if not didHandlerGrantPurchase then return nil end

		return true
	end)
	
	if not success then 
		warn("data store error, failed to process purchase: " .. result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local didGrantPurchase = result == true
	if didGrantPurchase then
		task.spawn(updateDonatedData, playerId, price)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

MarketPlaceService.ProcessReceipt = processReceipt