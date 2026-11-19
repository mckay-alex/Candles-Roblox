local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local showExitEvent = events:WaitForChild("ShowExitBtn")
local tpEvent = events:WaitForChild("Teleporting")

local exitGUI = script.Parent
local exitBTN = exitGUI.ExitFrame
local loadingGUI = exitGUI.Loading
local teleportGUI = ReplicatedStorage:WaitForChild("TelportGUI")
TeleportService:SetTeleportGui(teleportGUI)

local exitSound = exitGUI:WaitForChild("ExitSound")

tpEvent.OnClientEvent:Connect(function()
	exitBTN.Visible = false
	loadingGUI.Visible = true
	for i = 1, 0, -0.05 do
		loadingGUI.BackgroundTransparency = i
		task.wait(0.05)
	end
end)

showExitEvent.OnClientEvent:Connect(function()
	exitBTN.Visible = true
end)

exitBTN.ExitButton.Activated:Connect(function()
	exitBTN.Visible = false
	exitSound:Play()
	showExitEvent:FireServer()
end)

