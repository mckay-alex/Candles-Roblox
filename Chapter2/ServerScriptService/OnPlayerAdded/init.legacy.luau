local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local spawnedIn = false

local deathScreenRemote = game.ReplicatedStorage.Events.DeathScreen
local DeathScreenModule = require(script.DeathScreenServer)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Alive", true)
	-- going to add analytics here as well
	AnalyticsService:LogOnboardingFunnelStepEvent(player, 14, "JOINED_PHASETWO")
	
	player.CharacterAdded:Connect(function(character)
		if not spawnedIn then
			character.PrimaryPart:PivotTo(workspace.StartSpawns[math.random(1, #workspace.StartSpawns:GetChildren())].CFrame)
			task.spawn(function()
				character.PrimaryPart.Anchored = true
				task.wait(1)
				character.PrimaryPart.Anchored = false
			end)
			spawnedIn = true
		end
	
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.CollisionGroup = "non-zipPlayers"
			end
		end
		
		character.Humanoid.Died:Connect(function()
			player:SetAttribute("Alive", false)
		end)
		
		if not player:GetAttribute("Alive") then
			DeathScreenModule.diedSpawn(player)
		end
	end)	
end)