local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerDialogue = ReplicatedStorage.Events:WaitForChild("PlayerDialogue")

local RanPlayerChat = {}
local prevPlayerName

function RanPlayerChat.getPlayerIMG(player_id)
	local success, content = pcall(function()
		return Players:GetUserThumbnailAsync(player_id, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size180x180)
	end)
	return content
end

function RanPlayerChat.GetRandomPlayer()
	local playerList
	local alivePlayers = {}
	
	for i, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			table.insert(alivePlayers, player)
		end
	end
	
	if #alivePlayers == 0 then 
		playerList = Players:GetPlayers()
	else
		playerList = alivePlayers
	end
	
	local randomPlayer = playerList[math.random(1, #playerList)]
	
	if randomPlayer.Name == prevPlayerName and #playerList > 1 then
		local foundPlayer = table.find(playerList, randomPlayer)
		if foundPlayer then table.remove(playerList, foundPlayer) end
		randomPlayer = playerList[math.random(1, #playerList)]		
	end
	
	prevPlayerName = randomPlayer.Name
	return randomPlayer
end

function RanPlayerChat.PlayerChat(text)
	local randomPlayer = RanPlayerChat.GetRandomPlayer()
	local ranPlayerID = randomPlayer.UserId
	local ranPlayerName = randomPlayer.Name
	PlayerDialogue:FireAllClients(RanPlayerChat.getPlayerIMG(ranPlayerID), ranPlayerName, text)
end

return RanPlayerChat
