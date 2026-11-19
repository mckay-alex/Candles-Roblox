local AnalyticsService = game:GetService("AnalyticsService")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local Spawns = workspace:WaitForChild("Spawns")

local welcomeBadgeID = 594897577479939

local function awardWelcomeBadge(playerId)
	local success, badgeInfo = pcall(function()
		return BadgeService:GetBadgeInfoAsync(welcomeBadgeID)
	end)	

	if success then
		if badgeInfo.IsEnabled then
			local success, hasBadge = pcall(function()
				return BadgeService:UserHasBadgeAsync(playerId, welcomeBadgeID)
			end)

			if success then
				if hasBadge then return end
				
				local awardSuccess, result = pcall(function()
					return BadgeService:AwardBadge(playerId, welcomeBadgeID)
				end)
				
				if not result then warn("Failed to award badge.") end
			else
				warn(hasBadge)
			end	
		end
	else
		warn("Failed to reteive badge info")
	end	
end

Players.PlayerAdded:Connect(function(player)
	AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "JOINED_LOBBY")
	local character = player.Character or player.CharacterAdded:Wait()
	
	character.PrimaryPart:PivotTo(Spawns[math.random(1, #Spawns:GetChildren())].CFrame) 
		
	
	awardWelcomeBadge(player.UserId)
end)