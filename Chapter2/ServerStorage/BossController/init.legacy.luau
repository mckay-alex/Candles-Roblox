local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local BOSS = script.Parent

local BOSS_ATTACKS 
local BindableStoryEvent = ServerStorage.StoryEvent
local BOSS_EVENT = ServerStorage.BossAssetsServer.ServerBossEvent
local CLIENT_BOSS_EVENT = ReplicatedStorage.Events.BossEvents.RemoteBossEvent
local CUTSCENE_EVENT = ReplicatedStorage.Events.CutsceneEvent
local SendBossText = ReplicatedStorage.Events.BossEvents.SendBossText

local ATTACKS = {"Spikes", "Circle", "Fireball"}
local COOL_DOWN = 5
local START_LIVES = 3
local WAIT_TIME
local PHASE = 1
local PhaseTwoBegun = false
local PhaseThreeBegun = false

local attackCount 
local attackLimit 

local PHASEONE_LIMIT = Random.new():NextInteger(4, 6) -- original values are 4, 6
local PHASETWO_LIMIT = Random.new():NextInteger(6, 8) -- original values are 6, 8
local PHASETHREE_LIMIT = Random.new():NextInteger(8, 10) -- original values are 8, 10

local function initiateBoss()
	BOSS_ATTACKS = require(script.BossAttacks)
	BOSS.PrimaryPart.Anchored = true
	CLIENT_BOSS_EVENT:FireAllClients("INITIATE")
	BOSS:SetAttribute("Lives", START_LIVES)
	BOSS:SetAttribute("Timer", 0)
	BOSS_EVENT:Fire()
end
-- !!! to start, in main story will porbably have this in story script 
task.delay(5, initiateBoss)

local function getRandomPlayer()
	local alivePlayers = {}
	for i, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			table.insert(alivePlayers, player)
		end
	end
	if #alivePlayers == 0 then alivePlayers = Players:GetPlayers() end
	local ranPlayer = alivePlayers[math.random(1, #alivePlayers)]
	return ranPlayer
end

local function BossAttack()--, waitTime)
	local attackIndex = 1
	local currentAttack
	
	repeat
		if attackIndex > #ATTACKS then attackIndex = 1 end
		local ranPlayer = getRandomPlayer()
		if (ranPlayer.Character.Humanoid.Health <= 0) then 
			if #Players:GetPlayers() == 0 then return else task.wait(COOL_DOWN) continue end
		end
		
		currentAttack = ATTACKS[attackIndex]
		BOSS_ATTACKS[currentAttack](ranPlayer, PHASE)
		attackCount += 1
		attackIndex += 1
		task.wait(WAIT_TIME)		
		
	until attackCount >= attackLimit
	
	if currentAttack == "Meteor" or currentAttack == "Fireball" then task.wait(5) end
	BOSS_ATTACKS.Eruption(PHASE)
end

local connection

BOSS_EVENT.Event:Connect(function()
	attackCount = 0

	task.wait(COOL_DOWN)
	
	if BOSS:GetAttribute("Lives") == 0 then 
		BindableStoryEvent:Fire("BOSS_FINISHED")
	return end
	
	if BOSS:GetAttribute("Lives") == 3 then
		attackLimit = PHASEONE_LIMIT
		PHASE = 1
		WAIT_TIME = 2.5
		
	elseif BOSS:GetAttribute("Lives") == 2 then
		PHASE = 2
		if not PhaseTwoBegun then 
			PhaseTwoBegun = true
			table.insert(ATTACKS, "ArenaFire")
			attackLimit = PHASETWO_LIMIT 
			WAIT_TIME = 2
			
			SendBossText:FireAllClients("The candle... it's getting hotter.", true)			
			task.delay(4, function()
				SendBossText:FireAllClients()
			end)
		end

	
	elseif BOSS:GetAttribute("Lives") == 1 then
		PHASE = 3
		if not PhaseThreeBegun then 
			PhaseThreeBegun = true
			table.insert(ATTACKS, "Meteor")
			attackLimit = PHASETHREE_LIMIT 
			WAIT_TIME = 1.5
					
			SendBossText:FireAllClients("TIME TO BURN YOU ONCE AND FOR ALL!", true)
			task.delay(6, function()
				SendBossText:FireAllClients()
			end)
		end
	end
	
	task.wait(WAIT_TIME)
	BossAttack()
end)
