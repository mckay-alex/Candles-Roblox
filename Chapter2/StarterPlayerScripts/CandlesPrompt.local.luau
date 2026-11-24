local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = game.Players.LocalPlayer
local PlayerGUI = LocalPlayer.PlayerGui

local currentTween

if UserInputService.TouchEnabled then
	-- make GUI have click icon
	local promptUI = script.ProximityPrompt
	promptUI.Frame.ButtonFrame.Keyboard.Visible = false
	promptUI.Frame.ButtonFrame.ImageButton.Size = UDim2.new(0.75, 0, 0.75, 0)
	promptUI.Frame.ButtonFrame.ImageButton.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"
	
	local bossPromptUI = script.BossPrompt
	bossPromptUI.Frame.ButtonFrame.Keyboard.Visible = false
	bossPromptUI.Frame.ButtonFrame.ImageButton.Size = UDim2.new(0.75, 0, 0.75, 0)
	bossPromptUI.Frame.ButtonFrame.ImageButton.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"
	
end

if UserInputService.GamepadEnabled then
	-- make gui have x button
	local promptUI = script.ProximityPrompt
	promptUI.Frame.ButtonFrame.Keyboard.Visible = false
	promptUI.Frame.ButtonFrame.ImageButton.Image = "rbxasset://textures/ui/Controls/xboxX.png"
	
	local bossPromptUI = script.BossPrompt
	bossPromptUI.Frame.ButtonFrame.Keyboard.Visible = false
	bossPromptUI.Frame.ButtonFrame.ImageButton.Image = "rbxasset://textures/ui/Controls/xboxX.png"
end


local function getScreenGui()
	local screenGui = PlayerGUI:FindFirstChild("ProximityPrompts")
	if screenGui == nil then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ProximityPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGUI
	end
	return screenGui
end

local function setupCustomPrompt(prompt : ProximityPrompt, inputType)
	
	local gui = getScreenGui()
	
	local hiddenConnection
	local buttonHoldConnection
	local buttonEndConnection
	local triggeredConnection
	
	local promptUI = script:FindFirstChild(prompt.Name):Clone()
	promptUI.Adornee = prompt.Parent
	promptUI.Parent = gui
	
	local progress = promptUI.Frame.Progress
	promptUI.Frame.ButtonFrame.Keyboard.Text = prompt.KeyboardKeyCode.Name
	promptUI.Frame.ActionText.Text = prompt.ActionText
	
	buttonHoldConnection = prompt.PromptButtonHoldBegan:Connect(function()
		currentTween = TweenService:Create(progress, TweenInfo.new(prompt.HoldDuration), {Transparency = 0})
		currentTween:Play()
	end)

	buttonEndConnection = prompt.PromptButtonHoldEnded:Connect(function(input)
		currentTween:Cancel()
		progress.Transparency = 1
	end)
	
	hiddenConnection = prompt.PromptHidden:Connect(function()
		promptUI.Parent = nil	
		hiddenConnection:Disconnect()
		buttonHoldConnection:Disconnect()
		buttonEndConnection:Disconnect()
	end)
	
	local button = promptUI.Frame.ButtonFrame.ImageButton	
	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then

		local buttonDown = false

		button.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and
				input.UserInputState ~= Enum.UserInputState.Change then
				prompt:InputHoldBegin()
				buttonDown = true
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if buttonDown then
					buttonDown = false
					prompt:InputHoldEnd()
				end
			end
		end)
	end
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style == Enum.ProximityPromptStyle.Default then return end
	
	setupCustomPrompt(prompt, inputType)	
end)
