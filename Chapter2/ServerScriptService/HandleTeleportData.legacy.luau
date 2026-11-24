local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Configuration = ReplicatedStorage.Config
local allPlayersJoined = false
local startedTimer = false
local connection

local BindableStoryEvent = game.ServerStorage.StoryEvent
local ToggleEvent = ReplicatedStorage.Events.ToggleEvent

local WAIT_TIME = 15

Configuration:SetAttribute("playersJoined", 0)

Players.PlayerAdded:Connect(function(player)

	local joinData = player:GetJoinData()
	local teleportData = joinData.TeleportData

	Configuration:SetAttribute("PlayerCount", teleportData)
	Configuration:SetAttribute("playersJoined", Configuration:GetAttribute("playersJoined") + 1)

	if Configuration:GetAttribute("playersJoined") == teleportData then
		print("all players have joined")
		allPlayersJoined = true
	end
end)

connection = Configuration:GetAttributeChangedSignal("playersJoined"):Connect(function()
	if startedTimer then return end
	startedTimer = true
	for i = 1, WAIT_TIME do
		if allPlayersJoined then break end
		task.wait(1)
	end

	BindableStoryEvent:Fire("START")
	ToggleEvent:FireAllClients("START") 

	connection:Disconnect()
	Configuration:SetAttribute("playersJoined", nil)
	Configuration:SetAttribute("PlayerCount", nil)
end)