local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local Configuration = ReplicatedStorage:WaitForChild("Config")

local events = ReplicatedStorage:WaitForChild("Events")
local SendText = events:WaitForChild("SendText")
local SendVillianText = events:WaitForChild("SendVillianText")
local SendBossText = events:WaitForChild("BossEvents"):WaitForChild("SendBossText")
local PlayerDialogue = events:WaitForChild("PlayerDialogue")

local SoundEvent = events:WaitForChild("SoundEvent")

local storyGUI = Players.LocalPlayer.PlayerGui:WaitForChild("StoryGUI")
local bossGUI = Players.LocalPlayer.PlayerGui:WaitForChild("BossGUI")
local storyStatus = Players.LocalPlayer.PlayerGui:WaitForChild("StoryStatus")

local textSound = script:WaitForChild("TextTick")

if not UserInputService.TouchEnabled then
	print("not on mobile")
	local chesterGUI = storyGUI.DialogueFrame
	local playerGUI = storyGUI.PlayerFrame
	local villianGUI = storyGUI.VillianFrame

	chesterGUI.ImageFrame.ChesterName.TextSize = 26
	chesterGUI.TextInfo.TextSize = 32
	chesterGUI.Size = UDim2.new(0.5, 0, 0.16, 0)

	playerGUI.Size = UDim2.new(0.5, 0, 0.16, 0)
	playerGUI.TextInfo.TextSize = 32	

	villianGUI.TextInfo.TextSize = 32
end

Configuration:GetAttributeChangedSignal("Status"):Connect(function() 
	if not player:GetAttribute("Alive") then return end
	if Configuration:GetAttribute("Status") == nil then
		local closingTween = TweenService:Create(storyStatus.Frame.TextLabel, TweenInfo.new(1.5), {Transparency = 1})
		closingTween:Play()
		closingTween.Completed:Wait()
		storyStatus.Frame.Visible = false

	else
		storyStatus.Frame.Visible = true
		storyStatus.Frame.TextLabel.Transparency = 0
		storyStatus.Frame.TextLabel.BackgroundTransparency = 0.5
		TweenService:Create(storyStatus.Frame.TextLabel, TweenInfo.new(1), {Size = UDim2.new(1,0,1,0)}):Play()
		for i = 1, #Configuration:GetAttribute("Status") do
			storyStatus.Frame.TextLabel.Text = string.sub(Configuration:GetAttribute("Status"), 1, i)
			task.wait(0.06)
			textSound:Play()
		end	
	end
end)


SendText.OnClientEvent:Connect(function(text) 
	if not player:GetAttribute("Alive") then return end
	if text == nil then
		storyGUI.DialogueFrame.Visible = false 
	else
		storyGUI.DialogueFrame.Visible = true
		for i = 1, #text do
			storyGUI.DialogueFrame.TextInfo.Text = string.sub(text, 1, i)
			task.wait(0.04)
			textSound:Play()
		end
	end
end)


SendVillianText.OnClientEvent:Connect(function(text)
	if not player:GetAttribute("Alive") then return end
	if text == nil then 
		storyGUI.VillianFrame.Visible = false
	else
		storyGUI.VillianFrame.Visible = true
		for i = 1, #text do
			storyGUI.VillianFrame.TextInfo.Text = string.sub(text, 1, i)
			task.wait(0.05)
			textSound:Play()
		end
	end
end)


SendBossText.OnClientEvent:Connect(function(text, BOSS)
	if not player:GetAttribute("Alive") then return end
	if text == nil then
		bossGUI.BossMessage.Visible = false	
		bossGUI.BossDialogueFrame.Visible = false
		return end

	if BOSS then 
		bossGUI.BossDialogueFrame.Visible = true
		for i = 1, #text do
			bossGUI.BossDialogueFrame.TextInfo.Text = string.sub(text, 1, i)
			task.wait(0.05)
			textSound:Play()
		end	
	else
		bossGUI.BossMessage.TextInfo.Text = text
		bossGUI.BossMessage.Visible = true
	end
end)


PlayerDialogue.OnClientEvent:Connect(function(image_id, name, text)
	if not player:GetAttribute("Alive") then return end
	if text == nil then
		storyGUI.PlayerFrame.Visible = false		
	else
		storyGUI.PlayerFrame.PlayerImageFrame.PlayerImg.Image = image_id
		storyGUI.PlayerFrame.PlayerImageFrame.PlayerName.Text = name
		storyGUI.PlayerFrame.Visible = true
		for i = 1, #text do
			storyGUI.PlayerFrame.TextInfo.Text = string.sub(text, 1, i)
			task.wait(0.04)
			textSound:Play()
		end
	end
end)

-- !!! a client specific action sound 
SoundEvent.OnClientEvent:Connect(function(id, volume, speed, timePos)
	if not player:GetAttribute("Alive") then return end
	local sound = Instance.new("Sound")
	sound.TimePosition = timePos or 0
	sound.SoundId = id
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = speed or 1
	sound.Parent = workspace

	while not sound.IsLoaded do task.wait() end
	
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end)