local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local SOUND_MODULE = require(ReplicatedStorage.SoundModule)

local events = ReplicatedStorage.Events
local CutsceneEvent = events.CutsceneEvent
local BindableStoryEvent = ServerStorage.StoryEvent

local DAMAGE = 20
local LEVER_AMOUNT = 1
local Configuration = ReplicatedStorage.Config

local Security = {}
local SecurityRoom = workspace.SecurityRoom

local playersDamaged = {}

local attackAnim = Instance.new("Animation")
local walkAnim = Instance.new("Animation")
attackAnim.AnimationId = "rbxassetid://17638005998"
walkAnim.AnimationId = "rbxassetid://10921240218"

function Security.Attack(npc, target)
	CutsceneEvent:FireClient(target, "SECURITY_GUARD")
	local attackTrack = npc.Humanoid.Animator:LoadAnimation(attackAnim)
	target.Character.Humanoid:TakeDamage(DAMAGE)
	attackTrack:Play()	
	task.wait(0.5)
	target.Character.HumanoidRootPart:PivotTo(workspace.ReviveLocations.SecurityRoom.CFrame)
end

function Security.Patrol(npc, i)
	local humanoid = npc.Humanoid
	local humanoidRootPart = npc.HumanoidRootPart
	local walkTrack = humanoid.Animator:LoadAnimation(walkAnim)
	local rotateInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	
	task.spawn(function()
		while Configuration:GetAttribute("LeverCount") ~= LEVER_AMOUNT do
			humanoid:MoveTo(npc[i].Position)
			humanoidRootPart.Walk:Play()
			walkTrack:Play()
			walkTrack:AdjustSpeed(0.8)
			humanoid.MoveToFinished:Wait()
			humanoidRootPart.Walk:Pause()
			walkTrack:Stop()
			TweenService:Create(npc.HumanoidRootPart, rotateInfo, {CFrame = npc.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(-90), 0)}):Play()	
			task.wait(3)
			TweenService:Create(npc.HumanoidRootPart, TweenInfo.new(1, Enum.EasingStyle.Quad), {CFrame = npc.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(90), 0)}):Play()
			task.wait(1.5)
			if i == 2 then i = 1 else i = 2 end
		end
	end)	
end

function Security.Initialize()
	
	local i = math.random(1, 2) -- random starting targetPos
	for _, guard in CollectionService:GetTagged("Security") do
		guard.PrimaryPart:SetNetworkOwner(nil)

		local connection		
		connection = guard.PatrolArea.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)	
			if player and not playersDamaged[player.Name] then
				playersDamaged[player.Name] = true
				Security.Attack(guard, player)			
				task.wait(1)
				playersDamaged[player.Name] = nil	
			end
		end)
		
		Configuration:GetAttributeChangedSignal("LeverCount"):Connect(function()
			if Configuration:GetAttribute("LeverCount") == LEVER_AMOUNT then
				connection:Disconnect()
			end
		end)
		
		Security.Patrol(guard, i)
		if i == 1 then i = 2 else i = 1 end
	end
	
	for i = 1, LEVER_AMOUNT do
		local leverSpawns = SecurityRoom.SecurityLeverSpawns:GetChildren()
		local ranSpawn = leverSpawns[math.random(1, #leverSpawns)]
		local securityLever = ServerStorage.SecurityLever:Clone()
		securityLever.Parent = SecurityRoom	
		securityLever.PrimaryPart.CFrame = ranSpawn.CFrame	
		ranSpawn:Destroy()
	end
		
	for _, lever in CollectionService:GetTagged("SecurityLever") do
		lever.Lever.ProximityPrompt.Triggered:Connect(function(player)
			lever.Lever.ProximityPrompt:Destroy()
			SOUND_MODULE.ActionSound("rbxassetid://9125626281")
			Configuration:SetAttribute("LeverCount", Configuration:GetAttribute("LeverCount") + 1)
			lever.Lever.Anchored = true
			TweenService:Create(lever.Lever, TweenInfo.new(1), {CFrame = lever.LeverGoal.CFrame}):Play()		
		end)
	end
end

Configuration:GetAttributeChangedSignal("LeverCount"):Connect(function()
	if Configuration:GetAttribute("LeverCount") == LEVER_AMOUNT then
		CutsceneEvent:FireAllClients("SECURITY_FINISHED")
		task.delay(15, function()
			ReplicatedStorage.Events.ResetCutscene:FireAllClients()
		end)
		BindableStoryEvent:Fire("ATTACK")
	end
end)

return Security
