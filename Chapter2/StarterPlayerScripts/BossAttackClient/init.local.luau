local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer

local events = ReplicatedStorage:WaitForChild("Events")
local CLIENTBOSS_EVENT = events:WaitForChild("BossEvents"):WaitForChild("RemoteBossEvent")
local CLIENT_BOSS_ATTACKS

-- disconnect when lives are 0 or just destroy remote event
CLIENTBOSS_EVENT.OnClientEvent:Connect(function(attack, ...)
	if attack == "INITIATE" then 
		--CLIENT_BOSS_ATTACKS = require(script.ClientBossAttacks) -- !!! this iwll be in main game
		CLIENT_BOSS_ATTACKS = require(script.ClientBossAttacks)
		player.PlayerGui.BossHearts.Enabled = true
		end
	CLIENT_BOSS_ATTACKS[attack](...)
end)

