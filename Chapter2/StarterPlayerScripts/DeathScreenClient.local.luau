local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = game.Players.LocalPlayer
local deathScreenRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DeathScreen")
local Configuration = ReplicatedStorage:WaitForChild("Config")

local deathScreenGUI = player.PlayerGui:WaitForChild("DeathScreen")
local mainFrame = deathScreenGUI:WaitForChild("Frame")
local menu = mainFrame:WaitForChild("MenuFrame")
local reviveButton = menu.Revive.ReviveButton
local returnButton = menu.Return.ReturnButton
local reviveButtonFrame = menu.Revive.ReviveFrame
local timer = menu.Timer

local reviveSound = StarterGui:WaitForChild("ButtonSound")
local lobbySound = StarterGui:WaitForChild("ShopSound")

local reviveID = 3418112107

local function tpToLobby()
	returnButton.Active = false	
	reviveButton.Active = false
	lobbySound:Play()
	deathScreenRemote:FireServer("LOBBY")
end

local function revivePlayer()	
	if not Configuration:GetAttribute("Revivable") then return end
	reviveButton.Active = false
	reviveSound:Play()
	MarketPlaceService:PromptProductPurchase(player, reviveID)
	task.wait(1)
	reviveButton.Active = true
end

returnButton.Activated:Connect(tpToLobby)
reviveButton.Activated:Connect(revivePlayer)

reviveButton.MouseEnter:Connect(function()
	reviveButtonFrame.BackgroundColor3 = Color3.new(0, 0.6, 0)
end)

reviveButton.MouseLeave:Connect(function()
	reviveButtonFrame.BackgroundColor3 = Color3.new(0, 0.82, 0)
end)

Configuration:GetAttributeChangedSignal("Revivable"):Connect(function()
	if not Configuration:GetAttribute("Revivable") then
		reviveButton.Active = false
		reviveButton.Text = "Cannot Revive"
	end
end)

local function reviveTimer(reviveTime)
	for i = reviveTime, 1, -1 do
		if player:GetAttribute("Alive") then return end
		timer.Text = i
		task.wait(1)
	end
	timer.Visible = false
	reviveButton.Active = false
	reviveButton.Text = "Cannot Revive"		
end

deathScreenRemote.OnClientEvent:Connect(function(info, reviveTime)
	print(info)
	if info == "DIED" then 
		mainFrame.Visible = true
		reviveTimer(reviveTime)
		
	elseif info == "PURCHASED" then
		mainFrame.Visible = false
		timer.Visible = true
		reviveButton.Active = true
		reviveButton.Text = "Revive"
	end
end)
