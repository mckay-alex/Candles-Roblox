local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeTeleport = require(game.ServerScriptService.SafeTeleport)

local diedRoomSpawns = workspace.DeathRoom.DeathRoomSpawns:GetChildren()
local deathScreenRemote = ReplicatedStorage.Events.DeathScreen

local lobbyID = 73928793827808
local REVIVE_TIMER = 30
local Configuration = ReplicatedStorage.Config

local DeathScreen = {}

deathScreenRemote.OnServerEvent:Connect(function(player, info)
	if info == "LOBBY" then
		SafeTeleport(lobbyID, {player})
	end
end)

function DeathScreen.diedSpawn(player : Player)
	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")	
	hrp:PivotTo(diedRoomSpawns[math.random(1, #diedRoomSpawns)].CFrame)
	task.spawn(function()
		hrp.Anchored = true
		task.wait(1)
		hrp.Anchored = false
	end)

	deathScreenRemote:FireClient(player, "DIED", REVIVE_TIMER)
	for i = REVIVE_TIMER, 1, -1 do
		if player:GetAttribute("Alive") then return end
		task.wait(1)
	end

	task.wait(5) -- 5 second buffer to process purchase in case player buys at last second
	if player:GetAttribute("Alive") then return end
	SafeTeleport(lobbyID, {player})	
end

return DeathScreen
