local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")

local CutsceneEvent = game.ReplicatedStorage.Events.CutsceneEvent
local Abyss = workspace.BossRoom.BossChase.Abyss
local bossChaseFolder = ServerStorage.BossChase

local debounce = {}

local Chase = {}


local function Meteors()
	local METEOR_EVENT = game.ReplicatedStorage.Events.BossEvents.MeteorHit
	local METEOR_DMG = 20
	local METEOR_FALLTIME = 1.5
	local METEOR_WAIT = 0.1
	local METEOR_POSITIONS = {}
	local METEOR_HIT = {}
	local METEOR_AMOUNT = 15
	local connection 
	
	local meteorRanges = workspace.BossRoom.BossChase.MeteorRange
	
	connection = METEOR_EVENT.OnServerEvent:Connect(function(player, characterHit)
		if player and Players[player.Name] then
			if player.Name == characterHit.Name and not METEOR_HIT[player.Name] then
				METEOR_HIT[player.Name] = true
				player.Character:FindFirstChild("Humanoid"):TakeDamage(METEOR_DMG)
				task.delay(0.5, function()
					METEOR_HIT[player.Name] = nil		
				end)
			end		
		end
	end)
	
	for i = 1, #meteorRanges:GetChildren() do
		local currentRange = meteorRanges[i]
		for i = 1, METEOR_AMOUNT do 
			local ranX = math.random(currentRange.Position.X - currentRange.Size.X / 2.5 , currentRange.Position.X + currentRange.Size.X / 2.5)
			local ranZ = math.random(currentRange.Position.Z - currentRange.Size.Z / 2.5, currentRange.Position.Z + currentRange.Size.Z / 2.5)
			local ranPos = Vector3.new(ranX, currentRange.Position.Y, ranZ)
			table.insert(METEOR_POSITIONS, ranPos)		
		end
		CutsceneEvent:FireAllClients("CHASE_METEOR", METEOR_POSITIONS, METEOR_FALLTIME, METEOR_WAIT)	
		task.wait(1.5)
	end
	
	task.wait(10)
	connection:Disconnect()
end

function Chase.Initialize()
	local chaseWall = bossChaseFolder.BossChaseFire
	
	CutsceneEvent:FireAllClients("BOSS_CHASE")
	chaseWall.Parent = workspace
	local chaseWallTween = TweenService:Create(chaseWall, TweenInfo.new(10, Enum.EasingStyle.Linear), {CFrame = workspace.BossChaseGoal.CFrame})


	local bossChaseSpawns = workspace.PlayerSpawns.BossChaseSpawns:GetChildren()
	for i, player in Players:GetPlayers() do
		player.Character.PrimaryPart:PivotTo(bossChaseSpawns[math.random(1, #bossChaseSpawns)].CFrame)
		player.Character.Humanoid.WalkSpeed = 28
	end
	
	task.spawn(Meteors)
	
	task.wait(4)
	chaseWall.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChild("Humanoid") then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and not debounce[player.Name] then
				debounce[player.Name] = true
				hit.Parent.Humanoid.Health = 0
			end
		end
	end)
	
	chaseWallTween:Play()
	chaseWallTween.Completed:Wait()
	chaseWall:Destroy()
	bossChaseFolder.FinalBorder.Parent = workspace
end

Abyss.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") then
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not debounce[player.Name] then
			debounce[player.Name] = true
			hit.Parent.Humanoid.Health = 0
		end
	end
end)

return Chase
