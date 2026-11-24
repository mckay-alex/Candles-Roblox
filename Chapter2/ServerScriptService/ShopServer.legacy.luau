local MarketPlaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local GamepassReceipts = DataStoreService:GetDataStore("Gamepass_Receipts")
local Donated = DataStoreService:GetOrderedDataStore("Donated")

local medkitID = 1481742989
local bloxyColaID = 1485134901

local gamePassFunctions = {}
local gamePassData = {
	[medkitID] = {
		Name = "Medkit",
		Price = 200
	},
	
	[bloxyColaID] = {
		Name = "BloxyCola",
		Price = 25
	}
}

gamePassFunctions[medkitID] = function(player)
	local medkit = ServerStorage.Gamepasses.Medkit:Clone()
	medkit.Parent = player.Backpack 

	if not player.StarterGear:FindFirstChild("Medkit") then 
		local starterMedkit = medkit:Clone()
		starterMedkit.Parent = player.StarterGear
	end
end

gamePassFunctions[bloxyColaID] = function(player)
	local bloxyCola = ServerStorage.Gamepasses.BloxyCola:Clone()
	bloxyCola.Parent = player.Backpack

	if not player.StarterGear:FindFirstChild("BloxyCola") then
		local starterBloxyCola = bloxyCola:Clone()
		starterBloxyCola.Parent = player.StarterGear
	end 
end

Players.PlayerAdded:Connect(function(player)
	for i, v in gamePassFunctions do
		local hasGamePass
		
		local success, errorMsg  = pcall(function()
			hasGamePass = MarketPlaceService:UserOwnsGamePassAsync(player.UserId, i)
		end)

		if not success then warn(errorMsg) return end
		
		if hasGamePass then
			print("calling has gamepass function")
			gamePassFunctions[i](player)
		end
	end
end)

local function saveGamePassReceipt(player, receipt)
	local ATTEMPT_LIMIT = 5
	local ATTEMPT_WAIT = 0.5
	local ATTEMPT = 0
	local success, errorMsg
	
	repeat 
		success, errorMsg = pcall(function()
			GamepassReceipts:UpdateAsync(player.UserId, function(oldReceipts)
				if oldReceipts == nil then oldReceipts = {} end
				table.insert(oldReceipts, receipt)
				return oldReceipts
			end)
		end)
		ATTEMPT += 1
		task.wait(ATTEMPT_WAIT * ATTEMPT)
	until success or ATTEMPT >= ATTEMPT_LIMIT 

	if not success then 
		warn(
			"Failed to update data for player: " .. player.UserId .. " gamepass: " .. receipt.ID
		)
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

MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		local gamePassHandler = gamePassFunctions[gamePassId]
		if gamePassHandler == nil then 
			warn("no game pass function for gamepass: " ..gamePassId)		
			return end
		
		gamePassFunctions[gamePassId](player)
		print(player.Name .. " bought the " .. gamePassData[gamePassId].Name .. " gamepass.")
		
		-- create receipt
		local receipt = {
			Name = gamePassData[gamePassId].Name,
			ID = gamePassId, 
			Date = os.date("%x"), 
			Price = gamePassData[gamePassId].Price,
		}
			
		task.spawn(saveGamePassReceipt, player, receipt)	
		task.spawn(updateDonatedData, player.UserId, gamePassData[gamePassId].Price)
	end
end)
 