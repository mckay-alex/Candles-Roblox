local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DonationsBoard = workspace:WaitForChild("DonationBoard")
local donationGUI = DonationsBoard:WaitForChild("Board"):WaitForChild("SurfaceGui")
local donateButtons = donationGUI:WaitForChild("Frame"):WaitForChild("DonateButtons")

local DonatedEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DonatedEvent")

local player = game.Players.LocalPlayer
local donatedMessage = player.PlayerGui:WaitForChild("DonatedGUI"):WaitForChild("Frame")
local donatedtext = donatedMessage:WaitForChild("TextInfo")

for i, button in donateButtons:GetChildren() do
	if button:IsA("TextButton") then
		button.Activated:Connect(function()
			MarketplaceService:PromptProductPurchase(player, button:GetAttribute("ProductID"))
		end)
	end
end

DonatedEvent.OnClientEvent:Connect(function(text)
	donatedMessage.Visible = true
	donatedtext.Text = text
	task.wait(10)
	donatedMessage.Visible = false
end)