local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local events = ReplicatedStorage.Events
local TOGGLE_EVENT = events.ToggleEvent
local GAME_EVENT = events.GameEvent
local UPDATE_EVENT = events.UpdateEvent

local Configuration = ReplicatedStorage.Config
local VOTE_TIME = 10

local Vote = {}

local Votes = {
	["Yes"] = {},
	["No"] = {}
}

function Vote.Begin()
	TOGGLE_EVENT:FireAllClients("BOSS_VOTE_BEGIN")
	for i = VOTE_TIME, 0, -1 do
		Configuration:SetAttribute("VoteTimer", i)
		task.wait(1)
	end
	
	Debris:AddItem(GAME_EVENT, 5)
	Debris:AddItem(UPDATE_EVENT, 5)
	local winningChoice = Vote.WinningVote()
	return winningChoice
end

function Vote.WinningVote()
	local choice, highest = nil, 0
	
	for i, voted in Votes do 
		if #voted > highest then
			highest = #voted
			choice = i
		end
	end
	
	if not choice then 
		local randomChoices = {"Yes", "No"}
		choice = randomChoices[math.random(1, #randomChoices)]
	end
	
	return choice
end

GAME_EVENT.OnServerEvent:Connect(function(player, vote)
	for name, choice in Votes do
		local oldVote = table.find(choice, player.UserId)
		if oldVote  then
			table.remove(choice, oldVote)
			break			
		end
	end
	table.insert(Votes[vote], player.UserId)
	UPDATE_EVENT:FireAllClients(Votes)
end)

return Vote
