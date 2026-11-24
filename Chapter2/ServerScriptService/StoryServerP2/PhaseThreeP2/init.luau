local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local AnalyticsService = game:GetService("AnalyticsService")

local Wins = DataStoreService:GetOrderedDataStore("Wins")

local ranPlayerChat = require(script.Parent.RanPlayerChat)

local CHESTER = workspace.CampInstructor
local Configuration = ReplicatedStorage.Config

local events = ReplicatedStorage.Events
local SOUND_MODULE = require(ReplicatedStorage.SoundModule)
local SendText = events.SendText
local TOGGLE_EVENT = events.ToggleEvent
local CutsceneEvent = events.CutsceneEvent
local RESET_CUTSCENE = ReplicatedStorage.Events.ResetCutscene

local DIRECTIONS = workspace.ChesterDirections
local CHESTER_SPAWNS = workspace.ChesterSpawns
local BORDERS = workspace.StoryBorders
local PLAYER_SPAWNS = workspace.PlayerSpawns
local BOSS_READY = false
local ENDING_READY = false
local CHASE_ACTIVE = false

local PhaseThreeP2 = {}

local function awardEndingBadge(playerId, badgeId)
	local success, badgeInfo = pcall(function()
		return BadgeService:GetBadgeInfoAsync(badgeId)
	end)	

	if success then
		if badgeInfo.IsEnabled then
			local success, hasBadge = pcall(function()
				return BadgeService:UserHasBadgeAsync(playerId, badgeId)
			end)

			if success then
				if hasBadge then return end

				local awardSuccess, result = pcall(function()
					return BadgeService:AwardBadge(playerId, badgeId)
				end)

				if not result then warn("Failed to award badge.") end
			else
				warn(hasBadge)
			end	
		end
	else
		warn("Failed to reteive badge info")
	end	
end




local function incrementWin(value)
	if value == nil then value = 0 end
	local updatedValue = value + 1
	return updatedValue
end

local function updateWins(player : Player)
	local RETRY_LIMIT = 7
	local RETRY_WAIT = 0.5
	local RETRIES = 0
	local success, errorMsg

	repeat
		success, errorMsg = pcall(function()
			Wins:UpdateAsync(player.UserId, incrementWin)
		end)

		if not success then
			RETRIES += 1
			task.wait(RETRY_WAIT * RETRIES) 	
		end

	until success or RETRIES > RETRY_LIMIT
	if not success then warn("Failed to update player wins : " .. errorMsg) end
end


function PhaseThreeP2.Intro()
	
	SendText:FireAllClients("LOOK! A door opened! LET'S GO THROUGH!")
	Configuration:SetAttribute("ReviveLocation", "Zipline")
	task.wait(2)

	local ziplineAnim = Instance.new("Animation")
	ziplineAnim.AnimationId = "rbxassetid://17120393809"
	local ziplineTrack = CHESTER.Humanoid.Animator:LoadAnimation(ziplineAnim)

	local ziplineDirections = DIRECTIONS.ZiplineDirections:GetChildren()
	for i = 1, #ziplineDirections do
		CHESTER.Humanoid:MoveTo(ziplineDirections[i].Position)
		CHESTER.Humanoid.MoveToFinished:Wait(5)
	end

	CHESTER.PrimaryPart:PivotTo(workspace.ChesterZIPStart.CFrame)
	ziplineTrack:Play()
	TweenService:Create(CHESTER.HumanoidRootPart, TweenInfo.new(5), {CFrame = workspace.ChesterZIPGOAL.CFrame}):Play()

	task.wait(3)
	
	SendText:FireAllClients()
	
	task.wait(8)
	
	local escapeSpawns = PLAYER_SPAWNS.EscapeSpawns:GetChildren()
	for _, player in Players:GetPlayers() do
		if not player:GetAttribute("ziplining") then	
			player.Character.PrimaryPart:PivotTo(escapeSpawns[math.random(1, #escapeSpawns)].CFrame)		
		end	
	end

	task.wait(1)

	SendText:FireAllClients("DID EVERYONE MAKE IT THROUGH?")

	task.wait(5)

	SendText:FireAllClients()
	ranPlayerChat.PlayerChat("YEAH I THINK SO!")

	task.wait(6)

	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("THAT WAS CLOSE BUT WE ESCAPED FROM THAT HOOLIGAN!")

	task.wait(7)

	SendText:FireAllClients()
	ranPlayerChat.PlayerChat("LOOK! I think I see an exit over there!")

	task.wait(5)

	ranPlayerChat.PlayerChat()
	SendText:FireAllClients("GREAT! LET'S GET OUT OF THIS PLACE!")

	task.wait(5)

	SendText:FireAllClients()	
	PhaseThreeP2.FakeEscape()
end

function PhaseThreeP2.FakeEscape()
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 25, "FAKE_ESCAPE")
	end
	
	CutsceneEvent:FireAllClients("SETUP_FAKE_ESCAPE")
	
	task.wait(1)

	local fakeEscapeSpawns = PLAYER_SPAWNS.FakeEscapeSpawns:GetChildren()
	for _, player in Players:GetPlayers() do
		player.Character.PrimaryPart:PivotTo(fakeEscapeSpawns[math.random(1, #fakeEscapeSpawns)].CFrame)
		task.spawn(function()
			player.Character.PrimaryPart.Anchored = true
			task.wait(1)
			player.Character.PrimaryPart.Anchored = false
		end)	
	end
	CHESTER.HumanoidRootPart:PivotTo(CHESTER_SPAWNS.ChesterFakeEscape.CFrame)

	task.wait(7)

	SendText:FireAllClients("Follow me y'all!")

	task.wait(2)

	task.delay(3, function()
		SendText:FireAllClients()
	end)

	for i = 1, 2 do
		CHESTER.Humanoid:MoveTo(DIRECTIONS.EscapeDirections[i].Position)
		CHESTER.Humanoid.MoveToFinished:Wait(5)
	end

	task.wait(3)

	CutsceneEvent:FireAllClients("FAKE_ESCAPE")
	task.delay(14, function()
		RESET_CUTSCENE:FireAllClients()
	end)
	task.spawn(function()
		SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1840020822", 0.4, nil, 2)
	end)

	local elevatorSpawns = PLAYER_SPAWNS.ElevatorSpawns:GetChildren()
	for _, player in Players:GetPlayers() do
		player.Character.PrimaryPart:PivotTo(elevatorSpawns[math.random(1, #elevatorSpawns)].CFrame)
		task.spawn(function()
			player.Character.PrimaryPart.Anchored = true
			task.wait(1)
			player.Character.PrimaryPart.Anchored = false
		end)
	end

	task.wait(3)

	local exitDirections = DIRECTIONS.ExitDirections
	for i = 1, #exitDirections:GetChildren() do 
		CHESTER.Humanoid:MoveTo(exitDirections[i].Position)
		CHESTER.Humanoid.MoveToFinished:Wait(5)
	end
	CHESTER.PrimaryPart:PivotTo(CHESTER_SPAWNS.ChesterBossSpawn.CFrame)
	workspace.FakeEscapeBlack:Destroy()

	task.wait(9)
	PhaseThreeP2.Elevator()
end

local trappedTrack

function PhaseThreeP2.Elevator() 
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 26, "ELEVATOR")
	end
	
	Configuration:SetAttribute("Revivable", false)

	local elevator = workspace.Elevator
	elevator.Cab:SetNetworkOwner(nil)
	local elevatorConstraint = elevator.PrismaticConstraint
	local storyCandle = elevator.ElevatorCandles.StoryCandle
	local ELEVATOR_TARGET = -54
	
	task.wait(6)
	ranPlayerChat.PlayerChat("Where are we?... and where is Chester?")

	task.wait(5)
	
	ranPlayerChat.PlayerChat("I don't know.... Im scared... what should we do?")
	
	task.wait(5)
	
	ranPlayerChat.PlayerChat()
	SOUND_MODULE.ActionSound("rbxassetid://6098281781", 1)
	
	task.wait(1)
	for i = 1, 6 do 
		storyCandle.Particles.GLOW.Enabled = not storyCandle.Particles.GLOW.Enabled
		storyCandle.Particles.Flame.Enabled  = not 	storyCandle.Particles.Flame.Enabled 
		storyCandle.PointLight.Enabled = not storyCandle.PointLight.Enabled
		task.wait(0.15)
	end

	CutsceneEvent:FireAllClients("ELEVATOR")

	task.wait(3)

	ranPlayerChat.PlayerChat("Uhh... what just happened???")

	task.wait(6)
	
	ranPlayerChat.PlayerChat()

	task.wait(5)
	
	elevatorConstraint.TargetPosition = ELEVATOR_TARGET

	task.wait(19)
	
	local chesterAnim = Instance.new("Animation")
	chesterAnim.AnimationId = "rbxassetid://101729259276523"
	trappedTrack = CHESTER.Humanoid.Animator:LoadAnimation(chesterAnim)
	trappedTrack.Looped = true
	trappedTrack:Play()
	trappedTrack:AdjustSpeed(0.2)
	
	for i, player in Players:GetPlayers() do
		player.Character.Humanoid.WalkSpeed = 0
		player.Character.Humanoid.JumpHeight = 0
	end

	CutsceneEvent:FireAllClients("BOSS")
	-- time to let boss cutscene finish to accept remote event (to prevent exploiters)
	-- exactly 43.2 but i give some leeway
	-- there was a timing issue before so i'm going to tneed a more reliable method on events 
	-- attribute on server and a boolean in the client...
	-- whenever attribute changes we wait until boolean in client signifies cutscene is over then fire somehting over
	task.wait(40)
	BOSS_READY = true
end


function PhaseThreeP2.Boss()
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 27, "BOSS_FIGHT")
	end
	RESET_CUTSCENE:FireAllClients()
	local BOSS = ServerStorage.BossAssetsServer.Boss
	local bossSpawns = PLAYER_SPAWNS.BossSpawns:GetChildren()
	CutsceneEvent:FireAllClients("NO_REVIVE")

	for _, player in Players:GetPlayers() do
		player.Character.PrimaryPart:PivotTo(bossSpawns[math.random(1, #bossSpawns)].CFrame)
		task.spawn(function()
			player.Character.PrimaryPart.Anchored = true
			task.wait(1)
			player.Character.PrimaryPart.Anchored = false
		end)
	end	
	
	BOSS.Parent = workspace
	BOSS.PrimaryPart:PivotTo(workspace.BossRoom.BossSpawn.CFrame) 

	ServerStorage.BossAssetsServer.BossLifeCandles.Parent = workspace
	
	local bossAbyss = workspace.BossRoom.BossWalls.Abyss
	local debounce = {}
	bossAbyss.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not debounce[player.Name] then
			debounce[player.Name] = true
			player.Character.Humanoid.Health = 0
			task.delay(1, function()
				debounce[player.Name] = nil
			end)	
		end
	end)
end

function PhaseThreeP2.BossFinished()

	local Vote = require(script.Vote)

	CutsceneEvent:FireAllClients("BOSS_FINISHED")
	
	task.wait(27)
	local votedChoice = Vote.Begin() -- will yield thread for waitTime
	Configuration:SetAttribute("Status", "Voted for " .. votedChoice)
	
	task.wait(3)
	CutsceneEvent:FireAllClients(votedChoice)
	Configuration:SetAttribute("Status", nil)
	
	if votedChoice == "No" then
		task.wait(23)
		PhaseThreeP2.GoodEnding()
	else
		task.wait(33)
		ENDING_READY = true
		task.delay(10, function()
			if not CHASE_ACTIVE then PhaseThreeP2.BossChase() end
		end)
	end
end

function PhaseThreeP2.BossChase()
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 29, "BOSS_CHASE")
	end
	RESET_CUTSCENE:FireAllClients()
	local bossChase = ServerStorage.BossChase
	local bossChaseObby = bossChase:FindFirstChild("BossChaseObby")
	bossChaseObby.Parent = workspace	
	workspace.BossRoom.BossWalls.ObbyWall:Destroy()

	local Chase = require(script.Chase)
	Chase.Initialize() -- yields main thread
	task.wait(3)
	ranPlayerChat.PlayerChat("IT'S A DEAD END!")
	task.wait(4)
	ranPlayerChat.PlayerChat("WHAT SHOULD WE DO?")
	task.wait(4)
	ranPlayerChat.PlayerChat()
	
	local evilBadgeId = 585951663783515
	for i, player in Players:GetPlayers() do
		task.spawn(updateWins, player)
		awardEndingBadge(player.UserId, evilBadgeId)
	end
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 30, "EVIL_ENDING")
	end
	CutsceneEvent:FireAllClients("BAD_ENDING")
end




function PhaseThreeP2.GoodEnding()
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 31, "GOOD_ENDING")
	end
	trappedTrack:Stop()
	local forestSpawns = PLAYER_SPAWNS.FinalForestSpawns:GetChildren() 
	local forestDirections = DIRECTIONS.ForestDirections:GetChildren() 

	CutsceneEvent:FireAllClients("FOREST")

	task.wait(2)
	CHESTER:PivotTo(CHESTER_SPAWNS.ChesterForestSpawn.CFrame)

	for i, player in Players:GetPlayers() do 
		player.Character:PivotTo(forestSpawns[math.random(1, #forestSpawns)].CFrame)
		task.spawn(function()
			player.Character.PrimaryPart.Anchored = true
			task.wait(1)
			player.Character.PrimaryPart.Anchored = false
		end)
	end

	task.wait(10)

	SendText:FireAllClients("Alright folks, the cart should just be up this way.")
	
	task.wait(5)

	for i = 1, #forestDirections do
		CHESTER.Humanoid:MoveTo(forestDirections[i].Position)
		CHESTER.Humanoid.MoveToFinished:Wait()
	end

	task.wait(3)

	SendText:FireAllClients("Let's hop on the cart and get on out of here!")
	local goodBadgeId = 821847682045998
	for i, player in Players:GetPlayers() do
		task.spawn(updateWins, player)
		awardEndingBadge(player.UserId, goodBadgeId)
	end

	task.wait(5)	

	CutsceneEvent:FireAllClients("THE_END")
	
	task.wait(1)
	
	CHESTER:PivotTo(CHESTER_SPAWNS.ChesterCartPosition.CFrame) 
	SendText:FireAllClients()

	local endingCart = workspace.EndingCart
	local cartSeats = endingCart.CartSeats:GetChildren()
	local seatNum = 1
	for i, player in Players:GetPlayers() do
		player.Character.Humanoid.WalkSpeed = 0
		player.Character.Humanoid.JumpHeight = 0
		player.Character:PivotTo(cartSeats[seatNum].CFrame)
		seatNum += 1
	end	
end


TOGGLE_EVENT.OnServerEvent:Connect(function(player, info)
	if info == "BOSS" and BOSS_READY then
		BOSS_READY = false
		PhaseThreeP2.Boss()
	elseif info == "BAD_ENDING_CHASE" and ENDING_READY and not Configuration:GetAttribute("CHASE_ACTIVE") then
		CHASE_ACTIVE = true
		Configuration:GetAttribute("CHASE_ACTIVE", true)
		PhaseThreeP2.BossChase()
	end
end)

return PhaseThreeP2
