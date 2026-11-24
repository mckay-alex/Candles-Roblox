local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local ranPlayerChat = require(script.Parent.RanPlayerChat)
local SOUND_MODULE = require(ReplicatedStorage.SoundModule)

local Lever = require(script.Lever)
local Security
local Attack 
local Obby

local Configuration = ReplicatedStorage.Config
local CHESTER = workspace.CampInstructor

local events = ReplicatedStorage.Events
local SendText = events.SendText
local CutsceneEvent = events.CutsceneEvent
local RESET_CUTSCENE = events.ResetCutscene
local BindableStoryEvent = ServerStorage.StoryEvent

local DIRECTIONS = workspace.ChesterDirections
local CHESTER_SPAWNS = workspace.ChesterSpawns
local BORDERS = workspace.StoryBorders
local PLAYER_SPAWNS = workspace.PlayerSpawns

local PhaseOneP2 = {}

function PhaseOneP2.Intro()
	
	Configuration:SetAttribute("Revivable", true)
	Configuration:SetAttribute("ReviveLocation", "SecurityRoom")
	
	SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1841594035", 0.65, true)
	ranPlayerChat.PlayerChat("Umm... where are we?")
	
	task.wait(5)
	
	ranPlayerChat.PlayerChat()	
	SendText:FireAllClients("I... I have no idea.")
	
	task.wait(5)
	
	SendText:FireAllClients("I never knew this part of the camp existed.")
	
	task.wait(5)
	
	ranPlayerChat.PlayerChat("I don't feel safe in here, we need to find a way out!")
	
	task.wait(6)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("Hmm... let's try to search this room for something.")
	
	task.wait(3)
	
	Lever.PlaceLever()
end

function PhaseOneP2.Security(playerName)
	
	Lever = nil
	Security = require(script.Security)
	Debris:AddItem(workspace.StartRoom.StartDoor, 5)
	BORDERS.StartBorder:Destroy()
	SendText:FireAllClients(playerName .. " opened the door! Great Job!")
	
	task.wait(5)
	
	SendText:FireAllClients("Welp, looks like there is only one way to go, follow me everybody!")
	Security.Initialize()
	
	task.wait(3)
		
	for i = 1, #DIRECTIONS.SecurityDirections:GetChildren() do
		CHESTER.Humanoid:MoveTo(DIRECTIONS.SecurityDirections[i].Position)
		CHESTER.Humanoid.MoveToFinished:Wait()
		if i == 1 then
			SendText:FireAllClients()
			CutsceneEvent:FireAllClients("SECURITY_INTRO")
		end
	end
	
	task.wait(3)

	ranPlayerChat.PlayerChat("Who are those people?")

	task.wait(5)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("I don't know, but we should avoid them, they seem to be guarding something.")
	
	task.wait(6)
	
	CutsceneEvent:FireAllClients("SECURITY_DOOR")
	SendText:FireAllClients()
	ranPlayerChat.PlayerChat("I think we have to find a way to open that big door.")
	
	task.wait(5)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("Alright! I'll keep lookout over here, make sure not to get caught by those guards.")
	BORDERS.SecurityBorder:Destroy()
	
	task.wait(7)
	
	SendText:FireAllClients()
	SOUND_MODULE.ActionSound("rbxassetid://9116394876")
	Configuration:SetAttribute("Status", "Open The Security Door")
	
	task.wait(5)
	
	Configuration:SetAttribute("Status", nil)
end

function PhaseOneP2.AttackRoom()
	
	Security = nil
	Attack = require(script.Attack)
	Debris:AddItem(workspace.SecurityRoom.SecurityGuards, 6)
	
	task.wait(3)
	
	Configuration:SetAttribute("ReviveLocation", "AttackRoom")
	SendText:FireAllClients("Great everyone! We opened the door! Let's keep going.")
	CHESTER:PivotTo(CHESTER_SPAWNS.ChesterAttackSpawn.CFrame)
	local attackSpawns = PLAYER_SPAWNS.AttackSpawns:GetChildren()
	
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			player.Character:PivotTo(attackSpawns[math.random(1, #attackSpawns)].CFrame)
			task.spawn(function()
				player.Character.PrimaryPart.Anchored = true
				task.wait(1)
				player.Character.PrimaryPart.Anchored = false
			end)
		end
	end
	
	task.wait(4)
	
	SendText:FireAllClients()
	
	task.wait(1)
	
	local atmosphere = game.Lighting.Atmosphere
	atmosphere.Color = Color3.fromRGB(71, 165, 88)
	atmosphere.Decay = Color3.fromRGB(50, 120, 53)
	atmosphere.Glare = 1
	atmosphere.Haze = 10

	task.spawn(function()
		SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1838105901", 0.1, true, 2, 0.8)
	end)
	task.wait(7) 
	
	ranPlayerChat.PlayerChat("I don't have a good feeling about this place...")
	
	task.wait(6)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("Don't worry, we should be safe here, hopefully no security guards saw us back there.")
	
	task.wait(5)
	
	Attack.Initiliaze()
	
	task.wait(0.1)
	
	SOUND_MODULE.ActionSound("rbxassetid://5721957175", nil, 1.3)

	task.wait(1)	
	
	SendText:FireAllClients("QUICK... PLAY DEAD!")
	SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1837803400", 0.4, true)
	
	task.wait(1)

	BORDERS.AttackBorder:Destroy()
	CutsceneEvent:FireAllClients("CHESTER_DROP")
	
	task.wait(2)
	
	SendText:FireAllClients()
end

function PhaseOneP2.Obby()
	
	Attack = nil
	Obby = require(script.Obby)
	Obby.Initialize()
	task.spawn(function()
		SOUND_MODULE.SetAudio("MUSIC","rbxassetid://1836009626", 0.25, true, 3.5, 0.5)
	end)
	
	TweenService:Create(workspace.AttackRoomDoor, TweenInfo.new(8), {CFrame = workspace.AttackRoomDoor.CFrame * CFrame.new(0, 20, 0)}):Play()
	CutsceneEvent:FireAllClients("CHESTER_RISE")
	SendText:FireAllClients("That was a surprise! Is everyone okay?")
	
	task.wait(5)

	ranPlayerChat.PlayerChat("Yeah we're fine, but I'm scared! I don't want to go on!")
	
	task.wait(5)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("I understand but we have to keep going, we can't just stay here!")
		
	task.wait(5)
	
	ranPlayerChat.PlayerChat("But I don't want to run into more of those guards!")
	
	task.wait(5)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("Don't worry we won't! Just be careful and follow along.")
	
	workspace.AttackRoomDoor:Destroy()
	
	task.wait(6)
	
	SendText:FireAllClients()
	for i = 1, #DIRECTIONS.ObbyDirections:GetChildren() do
		CHESTER.Humanoid:MoveTo(DIRECTIONS.ObbyDirections[i].Position)
		CHESTER.Humanoid.MoveToFinished:Wait()
	end
	
	Configuration:SetAttribute("ReviveLocation", "Obby")
	local obbySpawns = PLAYER_SPAWNS.ObbySpawns:GetChildren()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			local ranSpawn = obbySpawns[math.random(1, #obbySpawns)]

			player.Character:PivotTo(ranSpawn.CFrame)

			if player.Character:FindFirstChild("Weapon") then
				player.Character.Weapon:Destroy()
			else
				player.Backpack:FindFirstChild("Weapon"):Destroy()
			end
		end	
	end
	
	BORDERS.ObbyBorder.CanCollide = true
	ranPlayerChat.PlayerChat("...This looks dangerous.")
	
	task.wait(5)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("...I agree... you know what? Let's look for another way out folks!")
	
	task.wait(7)
	
	SendText:FireAllClients()
	CHESTER.Humanoid:MoveTo(workspace.ObbyExit.Position)
	CutsceneEvent:FireAllClients("OBBY_DOOR")
	CHESTER.Humanoid.MoveToFinished:Wait(2)
	CutsceneEvent:FireAllClients("CHESTER_OBBY")

	task.wait(3)
	
	CHESTER.Humanoid:MoveTo(DIRECTIONS.ObbyDirections["4"].Position)
	
	task.wait(1)
	
	SendText:FireAllClients("... On second thought, it can't be that dangerous! I'll meet y'all on the other side!")
	
	task.wait(7)
	
	CHESTER.Humanoid:MoveTo(CHESTER_SPAWNS.ChesterObbyFinish.Position)
	
	task.wait(0.5)
	
	CHESTER:PivotTo(CHESTER_SPAWNS.ChesterObbyFinish.CFrame)
	SendText:FireAllClients()
	BORDERS.ObbyStartBorder:Destroy()	
	Obby.Timer()
end

return PhaseOneP2
