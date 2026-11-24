local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Configuration = ReplicatedStorage.Config
local Player = game.Players.LocalPlayer
local PlayerGUI = Player.PlayerGui

local events = ReplicatedStorage:WaitForChild("Events")
local TOGGLE_EVENT = events:WaitForChild("ToggleEvent")

TOGGLE_EVENT.OnClientEvent:Connect(function(info, ...)
	
	if info == "OBBY_BEGIN" then
		
		local obbyFolder = workspace.Obby
		
		for _, axe in obbyFolder.SwingingAxes:GetChildren() do
			local ranNum = Random.new():NextNumber(2, 3)
			
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://129028691168906"
			sound.Volume = 3
			sound.PlaybackSpeed = 0.7
			sound.RollOffMaxDistance = 50
			sound.Parent = axe.Swinger

			local defaultPos = axe.Swinger.CFrame
			local axeInfo = TweenInfo.new(ranNum, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut, -1, true)
			local tween = TweenService:Create(axe.Swinger, axeInfo, {CFrame = defaultPos * CFrame.Angles(0, 0, math.rad(80))}):Play()

			task.delay(0.5, function()
				while ReplicatedStorage.Config:GetAttribute("ObbyStatus") ~= "FINISHED" do
					task.wait(ranNum)
					sound:Play()
				end
				task.wait(5)
				axe:Destroy()
			end)
		end	

		for i = 1, #obbyFolder.ObbyThird.ObbyFires:GetChildren() do
			local obbyFire = obbyFolder.ObbyThird.ObbyFires[i]
			task.wait(1)

			local fireSound = Instance.new("Sound")
			fireSound.SoundId = "rbxassetid://7669883044"
			fireSound.Volume = 0.25
			fireSound.RollOffMaxDistance = 50
			fireSound.Parent = obbyFire.FireParticle
			
			task.spawn(function()
				while ReplicatedStorage.Config:GetAttribute("ObbyStatus") ~= "FINISHED" do
					fireSound:Play()
					task.wait(6)		
				end
			end)

		end

	elseif info == "OBBY_ALMOST" then
		if not Player:GetAttribute("Alive") then return end
		local connection
		PlayerGUI.EventsGUI.Obby.Visible = true
		task.delay(15, function()
			PlayerGUI.EventsGUI.Obby.Visible = false
		end)

		connection = Configuration:GetAttributeChangedSignal("ObbyTimer"):Connect(function()
			PlayerGUI.EventsGUI.Obby.Timer.Text = Configuration:GetAttribute("ObbyTimer")
		end)

		Configuration:GetAttributeChangedSignal("ObbyStatus"):Connect(function()
			if Configuration:GetAttribute("ObbyStatus") == "FINISHED" then
				connection:Disconnect()
				game.StarterGui.EventsGUI.Obby:Destroy()
				PlayerGUI.EventsGUI.Obby:Destroy()
			end
		end)
		
	elseif info == "BOSS_VOTE_BEGIN" then
		if not Player:GetAttribute("Alive") then return end
		local votingConnection 
		local votingGUI = PlayerGUI.EventsGUI.Voting
		votingGUI.Visible = true
		
		votingConnection = Configuration:GetAttributeChangedSignal("VoteTimer"):Connect(function()
			if Configuration:GetAttribute("VoteTimer") == 0 then
				votingConnection:Disconnect()
				votingGUI:Destroy()
			return end
			votingGUI.Header.Timer.Text = Configuration:GetAttribute("VoteTimer")
		end)	
	end
end)