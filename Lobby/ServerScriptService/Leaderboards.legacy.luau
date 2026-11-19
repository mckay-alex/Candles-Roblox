local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local GLOBAL_WINS = DataStoreService:GetOrderedDataStore("Wins")
local GLOBAL_DONATED = DataStoreService:GetOrderedDataStore("Donated")

local RANKED_AMOUNT = 100
local MINUTES = 60
local UPDATE_EVERY = 30 * MINUTES
local COOL_DOWN = 0.1

local nameCache = {}

local donatedLeaderboard = workspace.DonatedLeaderboard
local winsLeaderboard = workspace.WinsLeaderboard

local rankedDonatedBoard = donatedLeaderboard.Board.SurfaceGui.Frame.RankedPlayers
local rankedWinsBoard = winsLeaderboard.Board.SurfaceGui.Frame.RankedPlayers
local rankedPlayerFrame = script.PlayerRankUI

local function setPlayerRank(rank, entryKey, entryValue)
	local rankedPlayer = rankedPlayerFrame:Clone()
	local success, content = pcall(function()
		return Players:GetUserThumbnailAsync(entryKey, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)
	if not success then warn(content) end

	rankedPlayer.PlayerImageFrame.PlayerImg.Image = content
	rankedPlayer.RankFrame.Rank.Text = rank
	rankedPlayer.NumFrame.Amount.Text = entryValue
	
	return rankedPlayer
end

local function updateLeaderboard(selectedDataStore, selectedLeaderboard)
	local success, pages = pcall(function()
		return selectedDataStore:GetSortedAsync(false, RANKED_AMOUNT, 1)
	end)
	
	if not success then warn("Failed to get leaderboard", pages) return end
	
	for i, frame in selectedLeaderboard:GetChildren() do
		if frame:IsA("Frame") then frame:Destroy() end
	end
	
	local currentPage = pages:GetCurrentPage() 
	for rank, entry in currentPage do
		local userName
		local userID = entry.key
		if nameCache[userID] then 
			userName = nameCache[userID]
		else
			local success, errorMsg = pcall(function()
				userName = Players:GetNameFromUserIdAsync(userID)
			end)
			if not success then 
				userName = "[Unknown]"
				warn("Name fetch failed for userID: " .. userID)		
			end
		end

		local rankedPlayer = setPlayerRank(rank, entry.key, entry.value)

		if userName then
			rankedPlayer.Name = userName
			rankedPlayer.PlayerImageFrame.PlayerName.Text = userName
			nameCache[userID] = userName
		end

		rankedPlayer.Parent = selectedLeaderboard
		task.wait(COOL_DOWN)
	end
	
	print("updated ranked for: " .. selectedDataStore.Name)
end

while true do
	task.spawn(updateLeaderboard, GLOBAL_WINS, rankedWinsBoard)
	task.wait(5)
	task.spawn(updateLeaderboard, GLOBAL_DONATED, rankedDonatedBoard)
	task.wait(UPDATE_EVERY)
end