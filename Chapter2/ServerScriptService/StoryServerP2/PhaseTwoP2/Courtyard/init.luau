local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local ServerStorage = game:GetService("ServerStorage")

local events = ReplicatedStorage.Events
local CUTSCENE_EVENT = events.CutsceneEvent
local BindableStoryEvent = ServerStorage.StoryEvent

local DIRECTIONS = workspace.ChesterDirections
local FRUIT_AMOUNT = Random.new():NextInteger(4, 7)
local SEARCH_TIME = 30

local Courtyard = {}

function Courtyard.Search()
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 20, "STARTED_SEARCH")
	end
	local FruitModule = require(script.Fruit)
	local fruitFolder = Instance.new("Folder")
	fruitFolder.Name = "FruitFolder"
	fruitFolder.Parent = workspace
	
	local escapeCandleFolder = Instance.new("Folder")
	escapeCandleFolder.Name = "EscapeCandleFolder"
	escapeCandleFolder.Parent = workspace
	
	local candleSpawns = workspace.Courtyard.CourtyardCandles.CandleSpawns:GetChildren()
	local escapeCandle = ServerStorage.CourtyardStorage.EscapeCandle
	
	local fruits = ServerStorage.Fruit:GetChildren()
	local fruitSpawns = workspace.FruitSpawns
	
	repeat 
		local ranSpawn = fruitSpawns:GetChildren()[math.random(1, #fruitSpawns:GetChildren())]
		local fruit = fruits[math.random(1, 2)]:Clone()
		fruit.Handle.CFrame = ranSpawn.CFrame
		fruit.Parent = fruitFolder
		ranSpawn:Destroy()
		FRUIT_AMOUNT -= 1		
		
	until FRUIT_AMOUNT == 0
	
	fruitSpawns:Destroy()
	
	local ranCandleSpawn = candleSpawns[math.random(1, #candleSpawns)]
	escapeCandle.CFrame = ranCandleSpawn.CFrame
	escapeCandle.Parent = escapeCandleFolder
	FruitModule.SetupFruit(fruitFolder)
	
	task.wait(SEARCH_TIME)
	
	fruitFolder:Destroy()
	FruitModule = nil
	BindableStoryEvent:Fire("VILLIAN")
end

function Courtyard.VillianIntro()
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 22, "VILLIAN_INTRO")
	end
	local villian = ServerStorage.CourtyardVillian
	local villianDirections = DIRECTIONS.VillianDirections
	villian.Parent = workspace
	villian.PrimaryPart:PivotTo(villianDirections["1"].CFrame)
	villian.PrimaryPart:SetNetworkOwner(nil)

	CUTSCENE_EVENT:FireAllClients("VILLIAN_INTRO")
	
	task.spawn(function()
		for i = 1, #villianDirections:GetChildren() do 
			if i == 5 then task.wait(8) end
			villian.Humanoid:MoveTo(villianDirections[i].Position)
			villian.Humanoid.MoveToFinished:Wait()
		end
		
		task.wait(3)
		
		local roamingPositions = DIRECTIONS.VillianRoaming
		for i = 1, 3 do 
			task.wait(5)	
			villian.Humanoid:MoveTo(roamingPositions:GetChildren()[math.random(1, 2)].Position)
		end
		
		task.wait(8)

		villian.Humanoid:MoveTo(roamingPositions.VillianClose.Position)
		task.wait(1)
		CUTSCENE_EVENT:FireAllClients("VILLIAN_ANGER")
		task.wait(8)
		
		for i = 1, #DIRECTIONS.VillianExitDirections:GetChildren() do
			villian.Humanoid:MoveTo(DIRECTIONS.VillianExitDirections[i].Position)
			villian.Humanoid.MoveToFinished:Wait()
		end
	end)
end

function Courtyard.Hide()
	local characters = {}
	local safeCharacters = {}
	
	local part = Instance.new("Part")
	part.CFrame = workspace.CourtyardCheck.CFrame
	part.Size = Vector3.new(32, 24, 32)
	part.Anchored = true
	part.CanCollide = false	
	part.Transparency = 0.5
	part.Parent = workspace
		
	for _, player in Players:GetPlayers() do
		table.insert(characters, player.Character)
	end
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = characters
	
	local playersHiding = workspace:GetPartBoundsInBox(workspace.CourtyardCheck.CFrame, Vector3.new(30, 20, 30), overlapParams)
	
	for _, part in playersHiding do
		if part.Parent:FindFirstChild("Humanoid") and not safeCharacters[part.Parent] then
			safeCharacters[part.Parent] = true
		end		
	end
	
	for _, player in Players:GetPlayers() do
		if not safeCharacters[player.Character] then
			player.Character.Humanoid:TakeDamage(100)
		end
	end
end

return Courtyard
