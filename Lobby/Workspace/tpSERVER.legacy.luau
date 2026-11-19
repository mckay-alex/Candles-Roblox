local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local SafeTeleport = require(game.ServerScriptService.SafeTeleport)

local teleporter = script.Parent
local gui = teleporter.tpGUIPart.BillboardGui
local config = teleporter.Configuration

local countdownRunning = false
local teleportingSoon = false

local ShowExitEvent = ReplicatedStorage.Events:WaitForChild("ShowExitBtn")
local tpEvent = ReplicatedStorage.Events:WaitForChild("Teleporting")

local TP_TIME = 15
local playersWaiting = {}

local function Waiting()
	while config:GetAttribute("GUI_STATUS") == "Waiting" do 
		for i = 1, 3 do
			if config:GetAttribute("GUI_STATUS") == "Teleporting" then return end
			gui.Status.Text = "Waiting" .. string.sub("...", 1, i)
			task.wait(0.5)
		end
	end
end

local function Setup()
	table.clear(playersWaiting)
	teleportingSoon = false	
	gui.Player.Text = #playersWaiting .. "/" .. config:GetAttribute("MaxPlayers") .. " Players"
	config:SetAttribute("GUI_STATUS", "Waiting")
	task.spawn(Waiting)
end

Setup() 


local function GetPlayerObjects()
	local gamePlayersWaiting = {}
	for i, playerID in playersWaiting do
		local tpPlayer = Players:GetPlayerByUserId(playerID) -- this is fine won't error if player is in game
		if tpPlayer then
			table.insert(gamePlayersWaiting, tpPlayer)
		end
	end

	for i, player in gamePlayersWaiting do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 2, "TPING_TO_PHASEONE")
	end

	return gamePlayersWaiting
end

local function TeleportPlayers()
	local PHASE_ONE_ID = 78261663313888
	local server = TeleportService:ReserveServer(PHASE_ONE_ID)
	local options = Instance.new("TeleportOptions")
	local players = GetPlayerObjects()
	options:SetTeleportData(#players)
	options.ReservedServerAccessCode = server
	SafeTeleport(PHASE_ONE_ID, players, options)
	table.clear(playersWaiting)
end

local function TeleportPlayersSoon()

	for i, player in playersWaiting do
		local tpPlayer = Players:GetPlayerByUserId(player)
		if tpPlayer then
			tpEvent:FireClient(tpPlayer) 
		end	
	end

	teleportingSoon = true
	gui.Status.Text = "Teleporting..."

	TeleportPlayers()
	task.wait(10)
	Setup()
end

local function StartCountdown()
	countdownRunning = true

	for i = TP_TIME, 1, -1 do
		if #playersWaiting == config:GetAttribute("MaxPlayers") then
			if i > 3 then
				for i = 3, 1, -1 do
					gui.Status.Text = "Teleporting in " .. i
					task.wait(1)
					if #playersWaiting < 1 then
						countdownRunning = false
						Setup()
						return end
				end
				TeleportPlayersSoon()
				countdownRunning = false
				return 
			end
		end
		gui.Status.Text = "Teleporting in " .. i
		task.wait(1)
		if #playersWaiting < 1 then
			countdownRunning = false 
			Setup()
			return end
	end
	
	TeleportPlayersSoon()
	countdownRunning = false
end

teleporter.EntryCircle.Touched:Connect(function(hit)

	if hit.Parent:FindFirstChild("Humanoid") then

		local player = Players:GetPlayerFromCharacter(hit.Parent)	
		local isWaiting = table.find(playersWaiting, player.UserId)

		if player and not isWaiting and #playersWaiting < config:GetAttribute("MaxPlayers") and not teleportingSoon then
			table.insert(playersWaiting, player.UserId)
			config:SetAttribute("GUI_STATUS", "Teleporting")
			gui.Player.Text = #playersWaiting .. "/" .. config:GetAttribute("MaxPlayers") .. " Players"
			player.Character.HumanoidRootPart.CFrame = teleporter.tpIN.CFrame
			ShowExitEvent:FireClient(player)
			if not countdownRunning then
				StartCountdown()
			end
		end
	end
end)

ShowExitEvent.OnServerEvent:Connect(function(player)
	local isWaiting = table.find(playersWaiting, player.UserId)
	if isWaiting then
		table.remove(playersWaiting, isWaiting)
	end

	gui.Player.Text = #playersWaiting .. "/" .. config:GetAttribute("MaxPlayers") .. " Players"
	if player.Character then
		player.Character.HumanoidRootPart.CFrame = teleporter.tpOUT.CFrame
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local isWaiting = table.find(playersWaiting, player.UserId)
	if isWaiting then
		table.remove(playersWaiting, isWaiting)
		gui.Player.Text = #playersWaiting .. "/" .. config:GetAttribute("MaxPlayers") .. " Players"
	end
end)