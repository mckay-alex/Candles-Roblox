local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SOUND_EVENT = ReplicatedStorage.Events.SoundEvent

local Fruit = {}

local CHERRY_HEAL = 15
local PEAR_HEAL = 20

function Fruit.SetupFruit(fruitFolder)
	for i, fruit in fruitFolder:GetChildren() do
		local debounce = false
		local cooldown = false
		fruit.Activated:Connect(function() -- *** want to add check if player has full health then send message to them
			local humanoid = fruit.Parent:FindFirstChild("Humanoid")
			if humanoid and not cooldown then
				local player = Players:GetPlayerFromCharacter(humanoid.Parent)
				cooldown = true
				task.delay(0.5, function() cooldown = false end)
				if humanoid.Health >= 100 then 
					SOUND_EVENT:FireClient(player, "rbxassetid://122722708716061", 1.5, 0.3)
					return end

				SOUND_EVENT:FireClient(player, "rbxassetid://3043029786", 0.3)	
				if fruit.Name == "CherryHeal" then 
					humanoid.Health += CHERRY_HEAL
				else 
					humanoid.Health += PEAR_HEAL
				end		
				
				fruit:Destroy()
			end
		end)
		
		fruit.Handle.Touched:Connect(function(hit)
			if hit.Parent:FindFirstChild("Humanoid") and not debounce then
				debounce = true
				fruit.Handle.Anchored = false
				fruit.Clickhitbox:Destroy()
				fruit.Highlight:Destroy()
			end
		end)
		
		local clickDetector = fruit.Clickhitbox.ClickDetector
		
		clickDetector.MouseClick:Connect(function(player)
			debounce = true
			fruit.Handle.Anchored = false
			fruit.Parent = player.Character
			fruit.Highlight:Destroy()
			fruit.Clickhitbox:Destroy()
		end)
		
		clickDetector.MouseHoverEnter:Connect(function(player)
			fruit.Highlight.OutlineTransparency = 0.4
		end)
		
		clickDetector.MouseHoverLeave:Connect(function(player)
			fruit.Highlight.OutlineTransparency = 1
		end)
	end
end

return Fruit
