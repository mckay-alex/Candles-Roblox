local DataStoreService = game:GetService("DataStoreService") 
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ProductReceipts = DataStoreService:GetDataStore("Product_Receipts")
local Donated = DataStoreService:GetOrderedDataStore("Donated")

local DonatedEvent = game.ReplicatedStorage.Events.DonatedEvent

local Donate10_ID = 3440485196
local Donate100_ID = 3440487452

local Donate500_ID = 3440487448
local Donate1000_ID = 3440487449

local Donate10000_ID = 3440487450
local Donate100000_ID = 3440487451


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

local productFunctions = {}


productFunctions[Donate10_ID] = function(receiptInfo, player)
	local price = tonumber(receiptInfo.CurrencySpent)
	DonatedEvent:FireClient(player, "Thank you " .. player.Name .. " for donating " .. price)
	return true
end

productFunctions[Donate100_ID] = function(receiptInfo, player)
	local price = tonumber(receiptInfo.CurrencySpent)
	DonatedEvent:FireClient(player, "Thank you " .. player.Name .. " for donating " .. price)
	return true
end

productFunctions[Donate500_ID] = function(receiptInfo, player)
	local price = tonumber(receiptInfo.CurrencySpent)
	DonatedEvent:FireClient(player, "Thank you " .. player.Name .. " for donating " .. price)
	return true
end

productFunctions[Donate1000_ID] = function(receiptInfo, player)
	local price = tonumber(receiptInfo.CurrencySpent)
	DonatedEvent:FireClient(player, "Thank you " .. player.Name .. " for donating " .. price)
	return true
end

productFunctions[Donate10000_ID] = function(receiptInfo, player)
	local price = tonumber(receiptInfo.CurrencySpent)
	DonatedEvent:FireClient(player, "Thank you " .. player.Name .. " for donating " .. price)
	return true
end

productFunctions[Donate100000_ID] = function(receiptInfo, player)
	local price = tonumber(receiptInfo.CurrencySpent)
	DonatedEvent:FireClient(player, "Thank you " .. player.Name .. " for donating " .. price)
	return true
end


local function processReceipt(receiptInfo)
	local purchaseId = receiptInfo.PurchaseId
	local productId = receiptInfo.ProductId
	local playerId = receiptInfo.PlayerId
	local price = tonumber(receiptInfo.CurrencySpent)
	local playerProductKey = playerId .. "_" .. purchaseId
	print("purchased product" .. productId)

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