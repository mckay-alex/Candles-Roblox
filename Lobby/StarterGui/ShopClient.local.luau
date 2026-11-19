local MarketPlaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local blur = game.Lighting:WaitForChild("ShopBlur")
	
local shopGUI = player.PlayerGui.ShopGUI
local toggleShop = shopGUI.ToggleShop
local mainShopGUI = shopGUI.MainFrame

local shopSound = shopGUI:WaitForChild("ShopSound")
local buttonSound = shopGUI:WaitForChild("ButtonSound")

local bloxyColaButton = mainShopGUI.Items.BloxyCola.Price.PurchaseButton
local medkitButton = mainShopGUI.Items.Medkit.Price.PurchaseButton

local medkitID = 1481742989
local bloxyColaID = 1485134901

toggleShop.ToggleButton.Activated:Connect(function()
	shopSound:Play()
	mainShopGUI.Visible = not mainShopGUI.Visible
	blur.Enabled = mainShopGUI.Visible
	
	if mainShopGUI.Visible then
		TweenService:Create(camera, TweenInfo.new(0.3), {FieldOfView = 61}):Play()
	else
		TweenService:Create(camera, TweenInfo.new(0.3), {FieldOfView = 70}):Play()
	end	
end)

toggleShop.ToggleButton.MouseEnter:Connect(function()
	toggleShop.Background.ImageColor3 = Color3.fromRGB(210, 210, 210)
end)

toggleShop.ToggleButton.MouseLeave:Connect(function()
	toggleShop.Background.ImageColor3 = Color3.fromRGB(255, 255, 255)
end)

for i, itemGUI in mainShopGUI.Items:GetChildren() do
	if itemGUI:IsA("Frame") then
		local button = itemGUI.Price.PurchaseButton

		button.MouseEnter:Connect(function()
			local background = 	button.Parent
			background.BackgroundColor3 = Color3.new(0, 0.6, 0)	
		end)

		button.MouseLeave:Connect(function()
			local background = 	button.Parent
			background.BackgroundColor3 = Color3.new(0, 0.82, 0)
		end)
	end
end

bloxyColaButton.Activated:Connect(function(inputObject)
	buttonSound:Play()
	MarketPlaceService:PromptGamePassPurchase(player, bloxyColaID)
end)

medkitButton.Activated:Connect(function(inputObject)
	buttonSound:Play()
	MarketPlaceService:PromptGamePassPurchase(player, medkitID)
end)