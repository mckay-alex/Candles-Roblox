local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local TOGGLE_EVENT = events:WaitForChild("ToggleEvent")
local GAME_EVENT = events:WaitForChild("GameEvent")
local UPDATE_EVENT = events:WaitForChild("UpdateEvent")

local votingFrame = script.Parent
local votingButtons = votingFrame:WaitForChild("VotingButtons")
local voteSound = script:WaitForChild("VoteSound")

for i, button in votingButtons:GetDescendants() do
	if button:IsA("TextButton") then
		button.Activated:Connect(function()
			voteSound:Play()
			GAME_EVENT:FireServer(button.Name)
		end)
	end
end

UPDATE_EVENT.OnClientEvent:Connect(function(votes)
	for name, voteInfo in votes do
		local voteChoice = votingButtons:FindFirstChild(name)
		voteChoice.Tally.Text = #voteInfo
	end
end)