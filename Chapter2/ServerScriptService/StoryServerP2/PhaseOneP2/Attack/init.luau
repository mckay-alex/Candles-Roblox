local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local AttackController = require(script.AttackerController)
local BindableStoryEvent = ServerStorage.StoryEvent

local Attack = {}

local ATTACKERS_ACTIVE = true
local attackNPC = ServerStorage.AttackSequence.NPCAttacker
local NPCSpawns = workspace.NPCAttackSpawns

local runAnim = Instance.new("Animation")
runAnim.AnimationId = "rbxassetid://10921240218"

function Attack.Initiliaze()
	local amount = #Players:GetPlayers() -- calculate attacker count based on player count
	local maxAmount = #NPCSpawns:GetChildren()
	if amount > maxAmount then amount = maxAmount end

	for i = 1, amount do
		local attacker = attackNPC:Clone()
		attacker:PivotTo(NPCSpawns[i].CFrame)
		attacker.Parent = NPCSpawns
		attacker.PrimaryPart:SetNetworkOwner(nil)
		NPCSpawns[i]:Destroy()
	end

	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Alive") then
			local weapon = ServerStorage.AttackSequence.Weapon:Clone()
			weapon.Parent = player.Character
		end
	end
	task.delay(2, Attack.Attack)
end

function Attack.Attack()
	for _, attackNPC in CollectionService:GetTagged("Attacker") do
		task.spawn(function()
			while ATTACKERS_ACTIVE do
				task.wait(0.2)
				if attackNPC then
					if attackNPC.Humanoid.Health <= 0 then break end
					local target = AttackController.FindTarget(attackNPC)
					if target then
						AttackController.FindPath(attackNPC, target)
					end
				end
			end
		end)

		attackNPC.Humanoid.Running:Connect(function(speed)
			local runTrack = attackNPC.Humanoid.Animator:LoadAnimation(runAnim)
			if speed >= 10 then
				runTrack:Play()
				runTrack.Looped = false
			end
		end)

		attackNPC.Humanoid.Died:Connect(function()
			attackNPC.ATTACKERHITBOX:Destroy() 
			Debris:AddItem(attackNPC, 2)
		end)
	end
end

CollectionService:GetInstanceRemovedSignal("Attacker"):Connect(function()
	if #CollectionService:GetTagged("Attacker") == 1 then
		ATTACKERS_ACTIVE = false
		BindableStoryEvent:Fire("OBBY")
	end
end)

return Attack
