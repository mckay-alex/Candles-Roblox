local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local bossAssetsClient = ReplicatedStorage:WaitForChild("BossAssetsClient")

local CUTSCENE_EVENT = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CutsceneEvent")
local METEOR_EVENT = ReplicatedStorage:WaitForChild("Events"):WaitForChild("BossEvents"):WaitForChild("MeteorHit")
local METEOR_HIT = {}
local player = Players.LocalPlayer


CUTSCENE_EVENT.OnClientEvent:Connect(function(cutscene, meteorPositions, meteorFalltime, meteorWait)
	if cutscene ~= "CHASE_METEOR" then return end
	local meteorFolder = Instance.new("Folder", workspace)
	for _, position in meteorPositions do
		task.wait(meteorWait)

		local meteorRan = Random.new():NextInteger(-5, 5)
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
			
			local hitboxParams = OverlapParams.new()
			hitboxParams.FilterDescendantsInstances = workspace.BossRoom.BossChase.MeteorRange:GetChildren()
			hitboxParams.FilterType = Enum.RaycastFilterType.Exclude

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
end)