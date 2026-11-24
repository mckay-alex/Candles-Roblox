local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local playersDamaged = {}
local TOGGLE_EVENT = ReplicatedStorage.Events:WaitForChild("ToggleEvent")
local SendText = ReplicatedStorage.Events:WaitForChild("SendText")
local BindableStoryEvent = ServerStorage.StoryEvent
local Configuration = ReplicatedStorage.Config

local Obby = {}

local INITIAL_PLAYER_AMOUNT = #Players:GetPlayers()

local OBBY_TIME = 40
local DAMAGE = 20
local COOL_DOWN = 1

local finishedObby = {}
local failedObby = {}
local debounce = {}

local obbyFolder = workspace.Obby
local obbyFires = obbyFolder.ObbyThird.ObbyFires
local obbyKillPart = obbyFolder.ObbyAbyss.ObbyKillPart
local obbyComplete = obbyFolder.ObbyComplete

local function hitPlayer(hit)
	if hit.Parent:FindFirstChild("Humanoid") and not playersDamaged[hit.Parent] then
		playersDamaged[hit.Parent] = true
		hit.Parent.Humanoid:TakeDamage(DAMAGE)
		task.wait(COOL_DOWN)
		playersDamaged[hit.Parent] = nil		
	end
end

function Obby.Initialize()
	Obby.FireLevel()
	TOGGLE_EVENT:FireAllClients("OBBY_BEGIN")
	Configuration:SetAttribute("ObbyStatus", "ONGOING")

	for _, axe in obbyFolder.SwingingAxes:GetChildren() do
		axe.Blade.Touched:Connect(hitPlayer)
	end
end


function Obby.FireLevel()
	for i = 1, #obbyFires:GetChildren() do
		local connection2
		local obbyFire = obbyFires[i]
		task.wait(1)
		
		local fireHitbox = obbyFire:FindFirstChild("FireHitbox")
		if fireHitbox == nil then
			fireHitbox = obbyFire:WaitForChild("FireHitbox")
		end
		
		fireHitbox.Touched:Connect(hitPlayer)	
		task.spawn(function()			
			while Configuration:GetAttribute("ObbyStatus") ~= "FINISHED" do
				task.wait(3)
				fireHitbox.CanTouch = not fireHitbox.CanTouch 
				obbyFire.FireParticle.FireBase.Enabled = not obbyFire.FireParticle.FireBase.Enabled
				obbyFire.FireParticle.Specs.Enabled = not obbyFire.FireParticle.Specs.Enabled
			end
			obbyFire:Destroy()
		end)		
	end
end


obbyKillPart.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") and not debounce[hit.Parent] then
		debounce[hit.Parent] = true
		hit.Parent.Humanoid:TakeDamage(100)
		task.delay(3, function()
			debounce[hit.Parent] = nil
		end)
	end
end)

obbyComplete.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)

	if player and player.Character:FindFirstChild("Humanoid").Health > 0 then
		local playerFinished = table.find(finishedObby, player.Name)
		local playerFailed = table.find(failedObby, player.Name)
		
		if not playerFinished and not playerFailed then
			table.insert(finishedObby, player.Name)
			local total = #finishedObby + #failedObby
			if total == INITIAL_PLAYER_AMOUNT then
				Configuration:SetAttribute("ObbyStatus", "FINISHED")
			end
		end
	end
end)

function Obby.Timer()
	
	for i = OBBY_TIME, 0, -1 do
		if Configuration:GetAttribute("ObbyStatus") == "FINISHED" then break end

		if i == 15 then
			SendText:FireAllClients("C'mon folks! we can't stay here forever!")
			task.delay(5, function()
				SendText:FireAllClients()
				TOGGLE_EVENT:FireAllClients("OBBY_ALMOST")
			end)	
		end
		Configuration:SetAttribute("ObbyTimer", i)
		task.wait(1)
	end

	print("TIMERS UP")
	task.delay(3, function()
		debounce = nil
	end)
	Configuration:SetAttribute("ObbyStatus", "FINISHED")

	for _, player in Players:GetPlayers() do
		-- check failed player in case someone revived
		if player:GetAttribute("Alive") then
			if not table.find(finishedObby, player.Name) and not table.find(failedObby, player.Name) then
				if player:GetAttribute("ObbyImmunity") then continue end
				player.Character.Humanoid.Health = 0
			end
		end
	end
	
	BindableStoryEvent:Fire("PHASE_TWO")
end


for i, player in Players:GetPlayers() do
	local connection
	connection = player.Character.Humanoid.Died:Connect(function()
		if not table.find(failedObby, player.Name) then table.insert(failedObby, player.Name) end
		
		local finished = table.find(finishedObby, player.Name)
		if finished then table.remove(finishedObby, finished) end
		
		local total = #finishedObby + #failedObby
		if total == INITIAL_PLAYER_AMOUNT then
			Configuration:SetAttribute("ObbyStatus", "FINISHED")
		end	
	end)
	
	Configuration:GetAttributeChangedSignal("ObbyStatus"):Connect(function()
		if Configuration:GetAttribute("ObbyStatus") == "FINISHED" then
			connection:Disconnect()
		end
	end)
end

return Obby
