local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local ranPlayerChat = require(script.Parent.RanPlayerChat)
local Courtyard = require(script.Courtyard)
local SOUND_MODULE = require(ReplicatedStorage.SoundModule)

local Configuration = ReplicatedStorage.Config
local CHESTER = workspace.CampInstructor

local events = ReplicatedStorage.Events
local SendText = events.SendText
local SendVillianText = events.SendVillianText
local CutsceneEvent = events.CutsceneEvent
local BindableStoryEvent = ServerStorage.StoryEvent

local DIRECTIONS = workspace.ChesterDirections
local CHESTER_SPAWNS = workspace.ChesterSpawns
local BORDERS = workspace.StoryBorders
local PLAYER_SPAWNS = workspace.PlayerSpawns

local PhaseTwoP2 = {}

function PhaseTwoP2.Intro()
	local Atmosphere = game.Lighting.Atmosphere
	
	Configuration:SetAttribute("ReviveLocation", "Courtyard")
	task.delay(6, function()
		Atmosphere.Color = Color3.fromRGB(0, 9, 206)
		Atmosphere.Decay = Color3.fromRGB(0, 21, 107)
		Atmosphere.Haze = 2
	end)
	SendText:FireAllClients("I can't believe we made it through safely everyone!")
	
	task.wait(4)
	
	CHESTER.Humanoid:MoveTo(DIRECTIONS.ChesterPhaseTwoWalk.Position)
	
	task.wait(1)
	
	SendText:FireAllClients()
	CutsceneEvent:FireAllClients("PHASE_TWO")
	
	task.wait(1)
	
	task.spawn(function()
		SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1838592691", 0.2, true, 1, 0.45)
	end)
	
	CHESTER:PivotTo(CHESTER_SPAWNS.ChesterPhaseTwo.CFrame)
	local phaseTwoSpawns = PLAYER_SPAWNS.PhaseTwoSpawns:GetChildren()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			player.Character:PivotTo(phaseTwoSpawns[math.random(1, #phaseTwoSpawns)].CFrame)
			task.spawn(function()
				player.Character.PrimaryPart.Anchored = true
				task.wait(1)
				player.Character.PrimaryPart.Anchored = false
			end)
		end	
	end
	
	task.wait(3)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("I have a feeling the exit is right around the corner, come on folks!")
	
	task.wait(6)
	
	
	repeat CHESTER.Humanoid:MoveTo(DIRECTIONS.CourtyardDirections["1"].Position)
	until CHESTER.Humanoid.MoveToFinished:Wait()	
	SendText:FireAllClients()
	
	task.wait(3)
		
	ranPlayerChat.PlayerChat("What is this place???")
	SOUND_MODULE.SetAudio("AMBIENCE", "rbxassetid://9112751072", 0.08, true)
	
	task.wait(4)
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("I am not sure... let's look around and see if we can find anything that points to an exit!")
	
	task.wait(6)
	
	SendText:FireAllClients()
	SOUND_MODULE.ActionSound("rbxassetid://9116394876")
	Configuration:SetAttribute("Status", "Search The Courtyard")
	task.delay(5, function()
		Configuration:SetAttribute("Status", nil)
	end)
	
	
	Courtyard.Search() -- this function yields main thread
end

function PhaseTwoP2.Villian()
	
	CHESTER.PrimaryPart:PivotTo(DIRECTIONS.CourtyardDirections["1"].CFrame)
	local courtyardSpawns = PLAYER_SPAWNS.CourtyardSpawns:GetChildren()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			player.Character.PrimaryPart:PivotTo(courtyardSpawns[math.random(1, #courtyardSpawns)].CFrame)
		end
	end
	
	local courtyardBorders = BORDERS.CourtyardBorders
	courtyardBorders.CourtyardDoor.CanCollide = true
	TweenService:Create(courtyardBorders.CourtyardEntrance, TweenInfo.new(2), {CFrame = courtyardBorders.CourtyardEntrance.CFrame * CFrame.new(0, -10, 0)}):Play()
	
	task.wait(5)

	SendText:FireAllClients("Did anybody find anything?")

	task.wait(5)

	ranPlayerChat.PlayerChat("Not really, it seems like there is nowhere to go from here!")

	task.wait(7)
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("Well I found this candle :D, we need one for the cart anyways!")
	task.delay(1, function()
		workspace.CourtyardCandle:Destroy()
	end)
	
	local grabTrack = CHESTER.Humanoid.Animator:LoadAnimation(CHESTER.Configuration.Grab)
	grabTrack:Play()
	grabTrack:AdjustSpeed(0.5)
	SOUND_MODULE.ActionSound("rbxassetid://77072623407707", 0.2, 0.8)

	task.wait(7)

	ranPlayerChat.PlayerChat("That's good, but we need to find a way out of here.")

	task.wait(6)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("You're right... does anybody have any ideas?")
	
	task.wait(2)
	
	task.spawn(function()
		SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://9112763344", 0.2, false, 2)
	end)
	
	task.wait(5.5)
	
	SendText:FireAllClients()
	Courtyard.VillianIntro()
	SOUND_MODULE.Stop()	
	SOUND_MODULE.ActionSound("rbxassetid://1845405089")
	
	task.wait(2)
	
	SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://9039981149", 1, nil, 1, nil, 6.5)
	ranPlayerChat.PlayerChat("...What is that?")

	task.wait(2)
	
	ranPlayerChat.PlayerChat()	
	SendText:FireAllClients("QUICK! FOLLOW ME! HIDE!")
	task.delay(4, function()
		SendText:FireAllClients()
	end)
	CHESTER.Humanoid.WalkSpeed = 20
	repeat CHESTER.Humanoid:MoveTo(DIRECTIONS.CourtyardDirections.CourtyardHide.Position)	
	until CHESTER.Humanoid.MoveToFinished:Wait()
	
	task.wait(2)
	
	task.delay(5, function()
		Courtyard.Hide()
		ServerStorage.EscapeDoorBorder.Parent = workspace	
		SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1836814403", 0.6, nil, 3, 0.9)
	end)
	
	task.wait(10)

	SendVillianText:FireAllClients("These kindling intruders... where might they be?")
	
	task.wait(6)

	SendVillianText:FireAllClients()
	
	task.wait(3)
	
	SendVillianText:FireAllClients("Well... what do we have here? It appears they stole a candle...")
	
	task.wait(8)
	
	SendVillianText:FireAllClients("I cannot afford for them to burn the path of my grand summoning...")
	task.wait(9)
	
	SendVillianText:FireAllClients("In that case, once I find them I'll...")
	
	task.wait(5)

	SendVillianText:FireAllClients("ONCE I FIND THEM... I'LL... I'LL...")

	task.wait(5)

	SendVillianText:FireAllClients("...finding them will be the number one priority.")
	
	task.wait(6)
	
	SendVillianText:FireAllClients()
	
	task.wait(3)
	
	PhaseTwoP2.Escape()
end

function PhaseTwoP2.Escape()
	
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 23, "VILLIAN_FINISHED")
	end
	local escapeDoor = BORDERS.CourtyardBorders.EscapeDoor
	TweenService:Create(escapeDoor, TweenInfo.new(2), {Position = escapeDoor.Position - Vector3.new(0, 12, 0)}):Play()
	SendText:FireAllClients("Who... who is that??? Why was he talking about a grand summoning?")
	
	task.wait(10)

	SendText:FireAllClients()
	ranPlayerChat.PlayerChat("I DON'T KNOW!  WE NEED TO GET OUT OF HERE!!!")
	
	task.wait(7)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("...I think we have to go back out to escape.")
	
	task.wait(7)
	
	SendText:FireAllClients()
	ranPlayerChat.PlayerChat("WITH THAT GUY AROUND? I DON'T WANT TO GO ANYWHERE!")
	
	task.wait(7)
	
	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("It's probably best to avoid him. Let's search for something in this room then.")
	SOUND_MODULE.ChangeVolume("MUSIC", 0.25, 2)
	
	task.wait(8)
	
	SendText:FireAllClients()
	
	task.wait(1)

	CutsceneEvent:FireAllClients("COURTYARD_ESCAPE")
	
	task.wait(1)
	
	SendText:FireAllClients("HURRY! FIND SOMETHING!")
	local escapeCandle = workspace.EscapeCandleFolder.EscapeCandle
	escapeCandle.ProximityPrompt.Enabled = true
	escapeCandle.ProximityPrompt.Triggered:Connect(function()
		escapeCandle.ProximityPrompt:Destroy()
		
		TweenService:Create(workspace.CourtyardEscape, TweenInfo.new(2), {Position = workspace.CourtyardEscape.Position + Vector3.new(0, 12, 0)}):Play()
		SOUND_MODULE.ActionSound("rbxassetid://9125626281")	
		Debris:AddItem(escapeCandle, 10)	
		BindableStoryEvent:Fire("PHASE_THREE")
	end)	
end

return PhaseTwoP2
