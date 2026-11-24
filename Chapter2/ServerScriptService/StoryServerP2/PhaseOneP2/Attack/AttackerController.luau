local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local AttackerController = {}

local CampInstructor = workspace.CampInstructor
local attackNPCS = {}
local ATTACK_DMG = 10
local attackAnim = Instance.new("Animation")
attackAnim.AnimationId = "rbxassetid://17638005998"

task.delay(4, function()
	for _, attacker in CollectionService:GetTagged("Attacker") do
		table.insert(attackNPCS, attacker)
	end
end)

function AttackerController.CheckSight(attacker, target)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {attackNPCS, CampInstructor}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local direction = (target.Position - attacker.HumanoidRootPart.Position).Unit * 40
	local ray = workspace:Raycast(attacker.HumanoidRootPart.Position, direction, rayParams)

	if ray and ray.Instance:IsDescendantOf(target.Parent) then 
		return true 
	end

	return nil
end

function AttackerController.AttackTarget(attacker, target)
	local syctheSlash = attacker.SyctheSlash
	local attackTrack = attacker.Humanoid.Animator:LoadAnimation(attackAnim)

	if (attacker.HumanoidRootPart.Position - target.Position).Magnitude < 6 then
		attackTrack:Play()
		syctheSlash:Play()
		if target.Parent then
			target.Parent.Humanoid:TakeDamage(ATTACK_DMG)
		end 
		task.wait(0.8)
	end
end

function AttackerController.FindPath(attacker, target)
	local path = PathfindingService:CreatePath()
	path:ComputeAsync(attacker.HumanoidRootPart.Position, target.Position)

	local wayPoints = path:GetWaypoints() 

	if path.Status == Enum.PathStatus.Success then
		for _, waypoint in wayPoints do
			attacker.Humanoid:MoveTo(waypoint.Position)

			local timeOut = attacker.Humanoid.MoveToFinished:Wait(2)
			if not timeOut then
				AttackerController.FindPath(attacker, target)
				break
			end

			if AttackerController.CheckSight(attacker, target) then
				repeat
					attacker.Humanoid:MoveTo(target.Position)

					task.wait(0.2)
					AttackerController.AttackTarget(attacker, target)
					if target == nil or target.Parent == nil then break	

					end
				until not AttackerController.CheckSight(attacker, target) or attacker.Humanoid.Health <= 0 or target.Parent.Humanoid.Health <= 0 
				break
			end
		end		
	end
end

function AttackerController.FindTarget(attacker)
	local DISTANCE = 200
	local target = nil
	local potentialTargets = {}
	local seeTargets = {}

	local humanoid
	local humanoidRootPart

	for i, player in  Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart and humanoid.Health > 0 then
				table.insert(potentialTargets, humanoidRootPart)		
			end	
		end	
	end


	if #potentialTargets > 0 then
		for i, v in potentialTargets do
			if AttackerController.CheckSight(attacker, v) then
				table.insert(seeTargets, v)
			elseif #seeTargets == 0 and (attacker.HumanoidRootPart.Position - v.Position).Magnitude < DISTANCE then
				target = v
				DISTANCE = (attacker.HumanoidRootPart.Position - v.Position).Magnitude
			end
		end
	end

	if #seeTargets > 0 then
		DISTANCE = 200
		for i, v in seeTargets do
			if (attacker.HumanoidRootPart.Position - v.Position).Magnitude < DISTANCE then
				target = v
				DISTANCE = (attacker.HumanoidRootPart.Position - v.Position).Magnitude
			end
		end
	end

	return target		
end

return AttackerController
