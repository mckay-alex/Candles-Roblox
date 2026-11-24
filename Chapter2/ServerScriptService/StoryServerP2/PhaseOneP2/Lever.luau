local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")

local Lever = {}

local SOUND_MODULE = require(game.ReplicatedStorage.SoundModule)
local BindableStoryEvent = ServerStorage.StoryEvent

local startRoom = workspace.StartRoom
local lever = ServerStorage.StartLever
local LeverSpawns = startRoom.LeverSpawns:GetChildren()

function Lever.PlaceLever()
	local ranSpawn = LeverSpawns[math.random(1, #LeverSpawns)]
	lever.Parent = startRoom
	lever.PrimaryPart.CFrame = ranSpawn.CFrame
	
	lever.Lever.ProximityPrompt.Triggered:Connect(function(player)
		lever.Lever.ProximityPrompt:Destroy()	
		lever.Lever.Anchored = true
		TweenService:Create(lever.Lever, TweenInfo.new(0.5), {CFrame = lever.LeverGoal.CFrame}):Play()
		TweenService:Create(startRoom.StartDoor, TweenInfo.new(5), {Position = startRoom.StartDoor.Position + Vector3.new(0, 20, 0)}):Play()
		SOUND_MODULE.ActionSound("rbxassetid://9125626281")
		BindableStoryEvent:Fire("SECURITY", player.Name)
	end)
end

return Lever