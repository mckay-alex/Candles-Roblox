local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local SHAKE_SCREEN = require(script.Parent.Parent.ScreenShake)

local boss = workspace:WaitForChild("Boss")
local player = Players.LocalPlayer
local bossAssetsClient = ReplicatedStorage:WaitForChild("BossAssetsClient")

local bossAnimator = boss:WaitForChild("Humanoid"):WaitForChild("Animator")
local bossHRP = boss:WaitForChild("HumanoidRootPart")

local METEOR_EVENT = ReplicatedStorage.Events:WaitForChild("BossEvents"):WaitForChild("MeteorHit")
local bossSounds = Instance.new("Folder")
bossSounds.Name = "BossSounds"
bossSounds.Parent = workspace

local spikeAnim
local circleAnim
local meteorAnim

local spikeSound
local circleSound
local fireballSound
local explosiveSound 
local lingeringFireSound
local flameSound
local blowupSound
local meteorSound
local fallingSound
local chargeSound
local magicSound
local eruptionSound
local magicEruptionSound
local damageSound

local BOSS_SOUNDS = {}

local ARENA_RANGE = workspace:WaitForChild("BossRoom"):WaitForChild("BossArenaRange")

local BossAttacksClient = {}

function BossAttacksClient.INITIATE()
	spikeAnim = Instance.new("Animation")
	spikeAnim.AnimationId = "rbxassetid://86800418836145"
	
	circleAnim = Instance.new("Animation")
	circleAnim.AnimationId = "rbxassetid://101296578133714"

	meteorAnim = Instance.new("Animation")
	meteorAnim.AnimationId = "rbxassetid://102002516194121"
	
	local soundFolder = Instance.new("Folder")
	soundFolder.Name = "BossSounds"
	
	local function createSound(id, speed, volume)
		local sound = Instance.new("Sound", soundFolder)
		sound.SoundId = id	
		sound.PlaybackSpeed = speed or 1
		sound.Volume = volume or 0.5
		return sound
	end

	spikeSound = createSound("rbxassetid://18511965048", 0.8)
	circleSound = createSound("rbxassetid://3923230963", 0.8)
	fireballSound = createSound("rbxassetid://125088538822680")
	explosiveSound = createSound("rbxassetid://5801257793", 0.8)
	lingeringFireSound = createSound("rbxassetid://9114428748", 0.9)
	flameSound = createSound("rbxassetid://3518146972", 1.6, 0.6)
	blowupSound = createSound("rbxassetid://113216405853964", 1.5, 0.25)
	meteorSound = createSound("rbxassetid://9116407527", 1.3)
	fallingSound = createSound("rbxassetid://5870958093", 0.7)
	chargeSound = createSound("rbxassetid://9066063881", 0.6)
	magicSound = createSound("rbxassetid://5862482798", 0.4, 1)
	eruptionSound = createSound("rbxassetid://113216405853964", 0.8)
	magicEruptionSound = createSound("rbxassetid://96144156475300", 0.6, 1)
	damageSound = createSound( "rbxassetid://6373139209", 0.8)
	
	soundFolder.Parent = workspace
	
	ContentProvider:PreloadAsync({spikeAnim, circleAnim, meteorAnim, soundFolder})
end

function BossAttacksClient.SPIKES(spikePositions, warningTime)
	local SPIKE_SHAKE = 400
	local spikeTrack = bossAnimator:LoadAnimation(spikeAnim)

	spikeTrack:Play()
	spikeTrack:AdjustSpeed(0.7)
	
	local spikeWarningFolder = Instance.new("Folder")
	spikeWarningFolder.Name = "SpikeWarningFolder"
	spikeWarningFolder.Parent = workspace
		
	for i, pos in spikePositions do
		local spikeWarning = bossAssetsClient.Spikes.SpikeWarning:Clone()
		spikeWarning.Position = pos + Vector3.new(0, 1, 0)
		spikeWarning.Parent = spikeWarningFolder
	end

	spikeTrack:GetMarkerReachedSignal("SlowDown"):Connect(function()
		spikeTrack:AdjustSpeed(0.3)
	end)

	task.wait(warningTime / 2)
	
	spikeSound:Play()

	task.wait(warningTime / 2)

	spikeWarningFolder:Destroy()
	SHAKE_SCREEN.Shake(player.Character, 0.6, SPIKE_SHAKE)
	
	task.delay(warningTime * 2.5, function()
		spikeSound:Play()
	end)	
end

function BossAttacksClient.CIRCLE()
	local CIRCLE_SHAKE = 300
	local circleTrack = bossAnimator:LoadAnimation(circleAnim)

	circleTrack:Play()
	circleTrack:GetMarkerReachedSignal("GroundTouched"):Connect(function()
		SHAKE_SCREEN.Shake(player.Character, 0.3, CIRCLE_SHAKE)
		circleSound:Play()
	end)
end

function BossAttacksClient.FIREBALL(targetPos, hitboxPos, dynamicTweenTime)
	fireballSound:Play()
	
	local fireballWarning = bossAssetsClient.Meteor.MeteorWarning:Clone()
	local secondaryWarning = bossAssetsClient.Meteor.SecondaryWarning:Clone()
	
	fireballWarning.Position = Vector3.new(targetPos.X, ARENA_RANGE.Position.Y, targetPos.Z)
	fireballWarning.Parent = workspace
	
	secondaryWarning.Position = fireballWarning.Position + Vector3.new(0, 0.2, 0)
	secondaryWarning.Parent = workspace

	TweenService:Create(secondaryWarning, TweenInfo.new(dynamicTweenTime * 1.8), {Size = fireballWarning.Size}):Play()	
	Debris:AddItem(fireballWarning, dynamicTweenTime)
	Debris:AddItem(secondaryWarning, dynamicTweenTime)
end

function BossAttacksClient.FIREBALL_IMPACT(hitboxPos)
	local FIREBALL_SHAKE = 250
	SHAKE_SCREEN.Shake(player.Character, 1, FIREBALL_SHAKE)

	explosiveSound:Play()
	lingeringFireSound:Play()

	local explosion = bossAssetsClient.Fireballs.BossExplosion:Clone()  
	explosion.Position = Vector3.new(hitboxPos.X, ARENA_RANGE.Position.Y + 6, hitboxPos.Z)
	explosion.Parent = workspace

	Debris:AddItem(explosion, 2)
	for _, particle in explosion.Attachment:GetChildren() do
		if particle.Name == "Glows" then
			particle:Emit(25)
		else
			particle:Emit(15)
		end
	end

	local fireParticle = bossAssetsClient.Fireballs.LingeringFire:Clone()
	local fireSpecs = bossAssetsClient.Fireballs.Specs:Clone()

	local lingeringFire = Instance.new("Part") 
	lingeringFire.Name = "LingeringFire"
	lingeringFire.Shape = Enum.PartType.Cylinder
	lingeringFire.Material = Enum.Material.Neon
	lingeringFire.Position = Vector3.new(hitboxPos.X, ARENA_RANGE.Position.Y + 0.5, hitboxPos.Z)
	lingeringFire.Orientation = Vector3.new(0, 0, 90)
	lingeringFire.Size = Vector3.new(0.1, 2, 2)
	lingeringFire.Anchored = true
	lingeringFire.CanCollide = false
	lingeringFire.Transparency = 0.3
	lingeringFire.Color = Color3.new(0.98, 0.86, 0.69)
	fireSpecs.Parent = lingeringFire
	fireParticle.Parent = lingeringFire
	lingeringFire.Parent = workspace

	local radius = {Size = Vector3.new(0.2, 15, 15)}
	TweenService:Create(lingeringFire, TweenInfo.new(0.5), radius):Play()
	Debris:AddItem(lingeringFire, 5)

	task.delay(4, function()
		for _, particle in lingeringFire:GetChildren() do
			particle.Enabled = false
		end
	end)
end		

function BossAttacksClient.ARENA_FIRE(randomRangeCFrame)
	local FIRE_SHAKE = 500
		
	local fireParticles = bossAssetsClient.ArenaFire.FireParticles:Clone()
	fireParticles.CFrame = randomRangeCFrame
	fireParticles.Parent = workspace
	
	blowupSound:Play()
	flameSound:Play()
	SHAKE_SCREEN.Shake(player.Character, 0.7, FIRE_SHAKE)
	
	task.wait(1)
	for i, particle in fireParticles:GetChildren() do
		particle.Enabled = false
	end
	task.wait(3)
	fireParticles:Destroy()
end

function BossAttacksClient.METEOR(meteorPositions, meteorFalltime, meteorWait)
	local METEOR_SHAKE = 150
	local meteorTrack = bossAnimator:LoadAnimation(meteorAnim)

	local meteorFolder = Instance.new("Folder")
	meteorFolder.Name = "MeteorFolder"
	meteorFolder.Parent = workspace

	local METEOR_HIT = {}
	local hitboxParams = OverlapParams.new()
	hitboxParams.FilterDescendantsInstances = {ARENA_RANGE, boss}
	hitboxParams.FilterType = Enum.RaycastFilterType.Exclude

	meteorTrack:Play()
	meteorTrack:AdjustSpeed(0.6)

	meteorTrack:GetMarkerReachedSignal("Slowdown"):Connect(function()
		meteorTrack:AdjustSpeed(0.25)
	end)

	meteorSound:Play()
	fallingSound:Play()
	SHAKE_SCREEN.Shake(player.Character, (#meteorPositions * meteorWait), METEOR_SHAKE)
	
	local rng = Random.new()
	for _, position in meteorPositions do
		task.wait(meteorWait)

		local meteorRan = rng:NextInteger(-25, 25)
		local meteorWarning = bossAssetsClient.Meteor.MeteorWarning:Clone()
		local secondaryWarning = bossAssetsClient.Meteor.SecondaryWarning:Clone()
		local meteor = bossAssetsClient.Meteor.Meteor:Clone()

		meteorWarning.Position = position	
		meteorWarning.Parent = meteorFolder

		secondaryWarning.Position = position + Vector3.new(0, 0.2, 0)
		secondaryWarning.Parent = meteorFolder
		TweenService:Create(secondaryWarning, TweenInfo.new(2), {Size = meteorWarning.Size}):Play()

		meteor.Position = position + Vector3.new(meteorRan, 100, meteorRan)
		meteor.CFrame = CFrame.lookAt(meteor.Position, position) 
		meteor.Parent = meteorFolder
		local meteorTween = TweenService:Create(meteor, TweenInfo.new(meteorFalltime, Enum.EasingStyle.Cubic , Enum.EasingDirection.In), {Position = position})
		meteorTween:Play()

		meteorTween.Completed:Connect(function()
			meteor:Destroy()
			meteorWarning:Destroy()
			secondaryWarning:Destroy()

			local explosion = bossAssetsClient.Meteor.MeteorExplosion:Clone()
			explosion.Position = position
			explosion.Parent = meteorFolder
			for _, particle in explosion.Attachment:GetChildren() do
				particle:Emit(7)
			end
			
			local meteorHitBox = bossAssetsClient.Meteor.MeteorHitBox:Clone()
			meteorHitBox.Position = position
			meteorHitBox.Parent = meteorFolder

			local hitParts = workspace:GetPartsInPart(meteorHitBox, hitboxParams)
			for _, part in hitParts do

				if (Players:GetPlayerFromCharacter(part.Parent) == player) and part.Parent.Humanoid.Health >= 0 and not METEOR_HIT[part.Parent] then
					METEOR_HIT[part.Parent] = true
					METEOR_EVENT:FireServer(part.Parent)
					task.delay(0.5, function()
						METEOR_HIT[part.Parent] = nil		
					end)	
				end
			end			
		end)		
	end

	Debris:AddItem(meteorFolder, #meteorPositions * meteorWait + 1)
end 



function BossAttacksClient.ERUPTION(bossHRP, hitboxPosition)

	local eruptionFolder = Instance.new("Folder")
	eruptionFolder.Name = "EruptionFolder"

	local rockLight = bossAssetsClient.Eruption.RockLight:Clone()
	rockLight.Position = hitboxPosition
	rockLight.Parent = eruptionFolder

	local eruptionVFX = bossAssetsClient.Eruption.FlameExplosion:Clone()
	eruptionVFX.Position = bossHRP.Position + Vector3.new(-30, 30, 0) 
	for _, particle in eruptionVFX.Particles:GetChildren() do
		if particle.Name ~= "Rings" then
			particle.Enabled = true
		end					
	end
	
	eruptionVFX.Parent = eruptionFolder
	eruptionFolder.Parent = workspace
	chargeSound:Play()
	magicSound:Play()

	task.delay(9, function()
		rockLight:Destroy()
	end)
end

function BossAttacksClient.ERUPTION_EXPLOSION()
	
	local eruptionFolder = workspace:FindFirstChild("EruptionFolder")
	local eruptionVFX = eruptionFolder:FindFirstChild("FlameExplosion")
	local ERUPTION_SHAKE = 600
	
	eruptionSound:Play()
	magicEruptionSound:Play()
	SHAKE_SCREEN.Shake(player.Character, 2.5, ERUPTION_SHAKE)

	eruptionVFX.Particles.Explosion.Lifetime = NumberRange.new(4)
	eruptionVFX.Particles.Explosion.Size = NumberSequence.new(40)
	eruptionVFX.Particles.Explosion.Speed = NumberRange.new(100)
	eruptionVFX.Particles.Rings.Enabled = true
	eruptionVFX.Particles.Rings.Size = NumberSequence.new(10, 80)
	
	task.delay(1.2, function()
		for _, particle in eruptionVFX.Particles:GetChildren() do	
			particle.Enabled = false
		end
		task.wait(5)
		eruptionFolder:Destroy()
	end)
end

function BossAttacksClient.DAMAGED(phase)
	local bossHeartsGUI = player.PlayerGui.BossHearts
	local tweenInfo = TweenInfo.new(1.2)
	local newProperty = {ImageTransparency = 1}
	damageSound:Play()
	
	if phase == 1 then
		TweenService:Create(bossHeartsGUI.One.Heart, tweenInfo, newProperty):Play()
	elseif phase == 2 then
		TweenService:Create(bossHeartsGUI.Two.Heart, tweenInfo, newProperty):Play()
	else 
		TweenService:Create(bossHeartsGUI.Three.Heart, tweenInfo, newProperty):Play()		
	end
end

-- !!! ONLY FOR TESTING DELETE BEFORE CONVERTING BACK TO MAIN GAME
function BossAttacksClient.RERUN()
	local bossHeartsGUI = player.PlayerGui.BossHearts
	for i, frame in bossHeartsGUI:GetChildren() do
		frame.Heart.ImageTransparency = 0
	end
end

return BossAttacksClient