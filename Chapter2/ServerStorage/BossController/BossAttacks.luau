local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local BOSS = workspace.Boss
local bossHRP = BOSS.HumanoidRootPart
local ARENA_RANGE = workspace.BossRoom.BossArenaRange
local HIT_PLAYERS = {}

local remoteBossEvents = ReplicatedStorage.Events.BossEvents
local CLIENT_EVENT = remoteBossEvents.RemoteBossEvent
local METEOR_EVENT = remoteBossEvents.MeteorHit
local SendBossText = remoteBossEvents.SendBossText
local BOSS_EVENT = ServerStorage.BossAssetsServer.ServerBossEvent

local BossAttacks = {}

function BossAttacks.Spikes(target, phase)

	local SPIKE_DAMAGE = 20
	local SPIKE_POSITIONS = {}
	local SPIKED_PLAYERS = {}
	local WARNING_TIME = 1
	local SPIKE_AMOUNT

	local spikeUpTweenInfo = TweenInfo.new((WARNING_TIME / 4), Enum.EasingStyle.Sine, Enum.EasingDirection.Out)	

	if phase == 1 then 
		SPIKE_AMOUNT = Random.new():NextInteger(45, 55)
	else 
		SPIKE_AMOUNT = Random.new():NextInteger(65, 75)	
		SPIKE_DAMAGE = 25
	end

	for i = 1, SPIKE_AMOUNT do 
		local ranX = math.random((ARENA_RANGE.Position.X - ARENA_RANGE.Size.X / 2.25), (ARENA_RANGE.Position.X + ARENA_RANGE.Size.X / 2.25))
		local ranZ = math.random((ARENA_RANGE.Position.Z - ARENA_RANGE.Size.Z / 2.25), (ARENA_RANGE.Position.Z + ARENA_RANGE.Size.Z / 2.25))
		local ranPos = Vector3.new(ranX, ARENA_RANGE.Position.Y, ranZ)
		table.insert(SPIKE_POSITIONS, ranPos)
	end

	local spikeFolder = Instance.new("Folder")
	spikeFolder.Name = "SpikeFolder"
	spikeFolder.Parent = workspace

	CLIENT_EVENT:FireAllClients("SPIKES", SPIKE_POSITIONS,  WARNING_TIME)

	for _, pos in SPIKE_POSITIONS do
		local spikeClone = ServerStorage.BossAssetsServer.Spikes.Spike:Clone()
		spikeClone.Position = pos - Vector3.new(0, 10, 0)
		spikeClone.Parent = spikeFolder
		spikeClone.Touched:Connect(function(hit)
			if hit.Parent:FindFirstChild("Humanoid") and not SPIKED_PLAYERS[hit.Parent] then
				SPIKED_PLAYERS[hit.Parent]  = true
				hit.Parent.Humanoid:TakeDamage(SPIKE_DAMAGE)
				task.wait(1)
				SPIKED_PLAYERS[hit.Parent]  = nil
			end
		end)
	end

	task.wait(WARNING_TIME)

	for i, spike in spikeFolder:GetChildren() do
		TweenService:Create(spike, spikeUpTweenInfo, {Position = spike.Position + Vector3.new(0, 17, 0)}):Play()
	end

	task.wait(WARNING_TIME * 3)

	for i, spike in spikeFolder:GetChildren() do
		TweenService:Create(spike, TweenInfo.new(WARNING_TIME / 4), {Position = spike.Position - Vector3.new(0, 20, 0)}):Play()
	end

	task.delay(5, function()
		spikeFolder:Destroy()
	end)
end

function BossAttacks.Circle(target, phase)

	local CIRCLE_DAMAGE = 25
	local COOL_DOWN = 1
	local circleTweenInfo = TweenInfo.new(1.5 , Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local circleGoal = {Size = Vector3.new(250, 2, 250)}

	local circleTween
	local AMOUNT
	local bossHRPPos = bossHRP.Position
	if phase == 3 then AMOUNT = 5 else AMOUNT = 3 end

	for i = 1, AMOUNT do
		CLIENT_EVENT:FireAllClients("CIRCLE")
		task.delay(0.5, function()
			local circle = ServerStorage.BossAssetsServer.FlameCircle.Disc:Clone() 
			circle.Touched:Connect(function(hit)
				if hit.Parent:FindFirstChildOfClass("Humanoid") and not HIT_PLAYERS[hit.Parent] then
					HIT_PLAYERS[hit.Parent] = true
					hit.Parent.Humanoid:TakeDamage(CIRCLE_DAMAGE)	
					task.delay(0.5, function()
						HIT_PLAYERS[hit.Parent] = nil		
					end)
				end		
			end)
			circle.Position = Vector3.new(bossHRPPos.X, ARENA_RANGE.Position.Y + 1, bossHRPPos.Z)
			circle.Parent = workspace

			circleTween = TweenService:Create(circle, circleTweenInfo, circleGoal)
			circleTween:Play()
			circleTween.Completed:Wait()
			circleTween = nil
			circle:Destroy()
		end)
		task.wait(COOL_DOWN)
	end	
end

function BossAttacks.Fireball(target, phase)

	local FIREBALL_DAMAGE = 20
	local SPEED = 65
st	local startTime = time()
	local maxTime = 5
	local connection	

	local fireballFolder = Instance.new("Folder")
	fireballFolder.Name = "FireballFolder"
	fireballFolder.Parent = workspace

	local hitBox = ServerStorage.BossAssetsServer.Fireball.HitBox:Clone()
	hitBox.CanQuery = false
	hitBox.Position = bossHRP.Position + Vector3.new(0, 16, 0)
	hitBox.CFrame = CFrame.lookAt(hitBox.Position, target.Character.HumanoidRootPart.Position)
	hitBox.Color = Color3.fromRGB(255, 128, 6)
	hitBox.Transparency = 0
	hitBox.Material= Enum.Material.Neon
	
	-- creating visuals here, more simple
	local fireballParticles = ReplicatedStorage.BossAssetsClient.Fireballs.FireballParticles:Clone()
	fireballParticles.Parent = hitBox

	hitBox.Parent = fireballFolder
	
	local goal = {Position = target.Character.HumanoidRootPart.Position}
	local dynamicTweenTime = (bossHRP.Position - target.Character.HumanoidRootPart.Position).Magnitude / SPEED
	local hitBoxInfo = TweenInfo.new(dynamicTweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local hitboxTween = TweenService:Create(hitBox, hitBoxInfo, goal)

	CLIENT_EVENT:FireAllClients("FIREBALL", target.Character.HumanoidRootPart.Position, hitBox.Position, dynamicTweenTime, hitBox)
	hitboxTween:Play()

	connection = RunService.Heartbeat:Connect(function()
		if time() - startTime >= maxTime then	
			connection:Disconnect()
			BossAttacks.FireballImpact(hitBox)		
			return end

		if hitboxTween.PlaybackState == Enum.PlaybackState.Completed then	
			connection:Disconnect()
			BossAttacks.FireballImpact(hitBox)		
			return end

		local result = workspace:Blockcast(hitBox.CFrame, hitBox.Size, (hitBox.Position - target.Character.HumanoidRootPart.Position).Unit * -3)
		if result and result.Instance.Parent:FindFirstChild("Humanoid") then
			if Players:GetPlayerFromCharacter(result.Instance.Parent) then
				result.Instance.Parent.Humanoid:TakeDamage(FIREBALL_DAMAGE)
				connection:Disconnect()
				BossAttacks.FireballImpact(hitBox)
				return end
		end
	end)
end

function BossAttacks.FireballImpact(hitbox)
	local COOL_DOWN = 0.5
	local LINGERING_TICKS = 9
	local FIRE_DMG = 5
	
	local fireballFolder = workspace:FindFirstChild("FireballFolder")
	if fireballFolder then fireballFolder:Destroy() end
	CLIENT_EVENT:FireAllClients("FIREBALL_IMPACT", hitbox.Position)
	hitbox:Destroy()

	local lingeringHitBox = Instance.new("Part") 
	lingeringHitBox.Shape = Enum.PartType.Cylinder
	lingeringHitBox.Material = Enum.Material.Neon
	lingeringHitBox.Transparency = 1
	lingeringHitBox.Position = Vector3.new(hitbox.Position.X, ARENA_RANGE.Position.Y + 4.5, hitbox.Position.Z) 
	lingeringHitBox.Orientation = Vector3.new(0, 0, 90)
	lingeringHitBox.Size = Vector3.new(10, 15, 15) -- irght now hard coding the size but can use an radius arg if neccesary (going ot have to send that to client though for part ot be accurate size)
	lingeringHitBox.Anchored = true
	lingeringHitBox.CanCollide = false
	lingeringHitBox.Parent = workspace

	Debris:AddItem(lingeringHitBox, 5) 

	local lingeringParams = OverlapParams.new()
	lingeringParams.FilterType = Enum.RaycastFilterType.Exclude
	lingeringParams.FilterDescendantsInstances = {BOSS, ARENA_RANGE, lingeringHitBox}

	task.spawn(function()
		for i = 1, LINGERING_TICKS do
			local DAMAGED_PLAYERS = {}
			local lingeringQuery = workspace:GetPartsInPart(lingeringHitBox, lingeringParams) 
			for _, part in lingeringQuery do
				if part.Parent:FindFirstChild("Humanoid") and not DAMAGED_PLAYERS[part.Parent] then
					DAMAGED_PLAYERS[part.Parent] = true
					part.Parent.Humanoid:TakeDamage(FIRE_DMG)
				end
			end
			task.wait(COOL_DOWN)
		end
	end)
end

-- !!! starts in phase 2
local bossAnim = Instance.new("Animation")
bossAnim.AnimationId = "rbxassetid://112185309264814"
function BossAttacks.ArenaFire(target, phase)
	local FIRE_DAMAGE = 50
	local bossTrack : AnimationTrack = BOSS.Humanoid.Animator:LoadAnimation(bossAnim)
	local arenaFireRanges = workspace.BossRoom.ArenaFireRanges

	local safetyParams = OverlapParams.new()
	safetyParams.FilterDescendantsInstances = {BOSS, ARENA_RANGE, arenaFireRanges:GetChildren()}
	safetyParams.FilterType = Enum.RaycastFilterType.Exclude


	local randomRange = arenaFireRanges:GetChildren()[math.random(1, #arenaFireRanges:GetChildren())]
	randomRange.Transparency = 0.5
	local hitboxSize = Vector3.new(randomRange.Size.X, 20, randomRange.Size.Z)

	local warningTime = 0.8
	if bossTrack == nil then return end
	bossTrack:Play()
	bossTrack:GetMarkerReachedSignal("StartWarning"):Connect(function()
		-- total warning time is 2.9 seconds
		for i = 1, 7 do
			local warningTweenInfo = TweenInfo.new((warningTime / 2), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true)
			TweenService:Create(randomRange, warningTweenInfo, {Transparency = 1}):Play()
			task.wait(warningTime)
			if i > 3 then
				warningTime -= 0.05
			else
				warningTime -= 0.2
			end	
		end
		randomRange.Transparency = 1
	end)

	bossTrack:GetMarkerReachedSignal("ArenaFire"):Connect(function()
		CLIENT_EVENT:FireAllClients("ARENA_FIRE", randomRange.CFrame)
		local hitParts = workspace:GetPartBoundsInBox(randomRange.CFrame, hitboxSize, safetyParams)
		for i, part in hitParts do
			if part.Parent:FindFirstChild("Humanoid") then
				if not HIT_PLAYERS[part.Parent] then
					HIT_PLAYERS[part.Parent] = true
					part.Parent.Humanoid:TakeDamage(FIRE_DAMAGE)
					task.delay(0.5, function()
						HIT_PLAYERS[part.Parent] = nil
					end)				
				end
			end
		end
	end)
	task.wait(3)
	randomRange.Transparency = 1
end

-- !!! only in phase three
function BossAttacks.Meteor(target, phase)

	local METEOR_DMG = 10
	local METEOR_FALLTIME = 1.5
	local METEOR_WAIT = 0.1
	local METEOR_POSITIONS = {}
	local METEOR_HIT = {}
	local METEOR_AMOUNT = Random.new():NextInteger(70, 80)	
	local connection 

	for i = 1, METEOR_AMOUNT do 
		local ranX = math.random(ARENA_RANGE.Position.X - ARENA_RANGE.Size.X / 2.1, ARENA_RANGE.Position.X + ARENA_RANGE.Size.X / 2.1)
		local ranZ = math.random(ARENA_RANGE.Position.Z - ARENA_RANGE.Size.Z / 2.1, ARENA_RANGE.Position.Z + ARENA_RANGE.Size.Z / 2.1)
		local ranPos = Vector3.new(ranX, ARENA_RANGE.Position.Y + 0.5, ranZ)
		table.insert(METEOR_POSITIONS, ranPos)
	end

	CLIENT_EVENT:FireAllClients("METEOR", METEOR_POSITIONS, METEOR_FALLTIME, METEOR_WAIT)

	connection = METEOR_EVENT.OnServerEvent:Connect(function(player, characterHit)
		if player and Players[player.Name] then
			if player.Name == characterHit.Name and not METEOR_HIT[player.Character.Name] then
				METEOR_HIT[player.Character.Name] = true
				player.Character:FindFirstChild("Humanoid"):TakeDamage(METEOR_DMG)
				task.delay(0.5, function()
					METEOR_HIT[player.Character.Name] = nil		
				end)
			end		
		end
	end)

	task.delay((METEOR_AMOUNT * METEOR_WAIT) + 3, function()
		connection:Disconnect()
	end)
end

-- !!! keep anim in server, anim event determines hitbox
function BossAttacks.Eruption(phase)

	local eruptionAnim = Instance.new("Animation")
	eruptionAnim.AnimationId = "rbxassetid://128989877893100"
	game.ContentProvider:PreloadAsync({eruptionAnim})
	local eruptionTrack = BOSS.Humanoid.Animator:LoadAnimation(eruptionAnim)

	task.wait(2) -- let previous attack finish

	SendBossText:FireAllClients("Take shelter!")

	local hitBoxFolder = Instance.new("Folder")
	hitBoxFolder.Name = "HitboxFolder"
	hitBoxFolder.Parent = workspace

	local ranX = math.random((ARENA_RANGE.Position.X - ARENA_RANGE.Size.X / 2.5), (ARENA_RANGE.Position.X + ARENA_RANGE.Size.X / 2.5))
	local ranZ = math.random((ARENA_RANGE.Position.Z - ARENA_RANGE.Size.Z / 2.5), (ARENA_RANGE.Position.Z + ARENA_RANGE.Size.Z / 2.5))
	local ranPos = Vector3.new(ranX, ARENA_RANGE.Position.Y + 3, ranZ)

	local rockWall = ServerStorage.BossAssetsServer.Eruption.RockWall:Clone()
	rockWall.Position = ranPos
	rockWall.CFrame = CFrame.lookAt(rockWall.Position, bossHRP.Position - Vector3.new(0,22,0))
	rockWall.Anchored = true
	rockWall.Parent = hitBoxFolder

	local hitBox = Instance.new("Part")
	hitBox.Position = rockWall.Position + rockWall.CFrame.LookVector.Unit * -5
	hitBox.CFrame = CFrame.lookAt(hitBox.Position, bossHRP.Position - Vector3.new(0,22,0))
	hitBox.CanCollide = false
	hitBox.CanTouch = false
	hitBox.CanQuery = false
	hitBox.Anchored = true
	hitBox.Transparency = 1
	hitBox.Size = Vector3.new(10, 20, 10)
	hitBox.Parent = hitBoxFolder

	local safetyParams = OverlapParams.new()
	safetyParams.FilterDescendantsInstances = {BOSS, ARENA_RANGE}
	safetyParams.FilterType = Enum.RaycastFilterType.Exclude

	CLIENT_EVENT:FireAllClients("ERUPTION", bossHRP, hitBox.Position)

	eruptionTrack:Play()
	eruptionTrack:AdjustSpeed(0.1)

	eruptionTrack:GetMarkerReachedSignal("Eruption"):Connect(function()

		eruptionTrack:AdjustSpeed(0.4)
		CLIENT_EVENT:FireAllClients("ERUPTION_EXPLOSION")
		local safetyBox = workspace:GetPartsInPart(hitBox, safetyParams)
		local safetyPlayers = {}
		for _, part in safetyBox do
			if part.Parent:FindFirstChild("Humanoid") and not table.find(safetyPlayers, part.Parent) then 
				table.insert(safetyPlayers, part.Parent)
			end
		end

		for _, player in Players:GetPlayers() do
			if not table.find(safetyPlayers, player.Character) then
				player.Character.Humanoid:TakeDamage(100)
			end
		end
	end)

	eruptionTrack:GetMarkerReachedSignal("Finished"):Connect(function()
		eruptionTrack:AdjustSpeed(0.1)
		Debris:AddItem(hitBoxFolder, 3)
		BossAttacks.Vulnerable(phase)
	end)
end

-- !!! yields, gives players time to put out candles (boss lives) 
-- !!! handle visuals on server, much simpler
function BossAttacks.Vulnerable(phase)

	local vulnerableAnim = Instance.new("Animation")
	vulnerableAnim.AnimationId = "http://www.roblox.com/asset/?id=10714360343"
	local vulnerableTrack = BOSS.Humanoid.Animator:LoadAnimation(vulnerableAnim)

	task.wait(3)

	SendBossText:FireAllClients("Put out candle!")
	local safetyCandleSound = Instance.new("Sound")
	safetyCandleSound.SoundId = "rbxassetid://9125644905"
	safetyCandleSound.PlaybackSpeed = 0.7
	safetyCandleSound.Parent = workspace

	vulnerableTrack:Play()
	safetyCandleSound:Play()

	local MAX_TIME = 10
	local connection

	local candleFolder = workspace.BossLifeCandles:GetChildren()
	local ranCandle = candleFolder[math.random(1, #candleFolder)] 
	ranCandle.LifeParticles.SafetyParticles.Enabled = true
	ranCandle.SafetyLight.Enabled = true
	ranCandle.BossPrompt.Enabled = true

	connection = ranCandle.BossPrompt.Triggered:Connect(function()	
		CLIENT_EVENT:FireAllClients("DAMAGED", phase)
		ranCandle.BossPrompt:Destroy()	
		for i, particle in ranCandle.LifeParticles:GetChildren() do 
			particle:Emit(10)
		end
		BOSS:SetAttribute("Timer", MAX_TIME)
		BOSS:SetAttribute("Lives", BOSS:GetAttribute("Lives") - 1)
		task.delay(0.3, function()
			ranCandle:Destroy()
		end)
	end)

	for i = 1, MAX_TIME do
		if BOSS:GetAttribute("Timer") == MAX_TIME then break end
		BOSS:SetAttribute("Timer", i)
		task.wait(1)
	end

	vulnerableTrack:Stop()
	connection:Disconnect()
	BOSS:SetAttribute("Timer", 0)	
	BOSS_EVENT:Fire()

	task.wait(1)

	if ranCandle.Parent ~= nil then
		ranCandle.BossPrompt.Enabled = false
		ranCandle.LifeParticles.SafetyParticles.Enabled = false
		ranCandle.SafetyLight.Enabled = false
	end

	safetyCandleSound:Destroy()
	SendBossText:FireAllClients()
end

return BossAttacks