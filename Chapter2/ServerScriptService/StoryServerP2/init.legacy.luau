local ServerStorage = game:GetService("ServerStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local CampInstructor = workspace.CampInstructor
CampInstructor.PrimaryPart:SetNetworkOwner(nil)
CampInstructor.PrimaryPart:PivotTo(workspace.ChesterSpawns.ChesterStartSpawn.CFrame)

local BindableStoryEvent = ServerStorage.StoryEvent

local PhaseOne = require(script.PhaseOneP2)
local PhaseTwo
local PhaseThree

-- !!! going to clean up code first before adding analytics service
local function logAnalytics(stepNumber, stepName)
	for i, player in Players:GetPlayers() do
		AnalyticsService:LogOnboardingFunnelStepEvent(player, stepNumber, stepName)
	end
end

BindableStoryEvent.Event:Connect(function(event, ...)
	if event == "START" then
		task.wait(5)
		logAnalytics(15, "STARTED_PHASETWO")
		PhaseOne.Intro()

	elseif event == "SECURITY" then
		local playerName = ...
		logAnalytics(16, "ENTER_SECURITY_ROOM")
		PhaseOne.Security(playerName)

	elseif event == "ATTACK" then
		logAnalytics(17, "ENTERING_ATTACK_ROOM")
		PhaseOne.AttackRoom()

	elseif event == "OBBY" then
		logAnalytics(18, "ENTERING_OBBY")
		PhaseOne.Obby()	

		----------------------- PHASE TWO -------------------------------

	elseif event == "PHASE_TWO" then
		PhaseOne = nil
		PhaseTwo = require(script.PhaseTwoP2)	
		logAnalytics(19, "ENTERING_PHASETWOP2")
		PhaseTwo.Intro()


	elseif event == "VILLIAN" then
		for i, player in Players:GetPlayers() do
			AnalyticsService:LogOnboardingFunnelStepEvent(player, 21, "SEARCH_COMPLETE")
		end
		PhaseTwo.Villian()

		----------------------- PHASE THREE -------------------------------

	elseif event == "PHASE_THREE" then
		PhaseTwo = nil
		PhaseThree = require(script.PhaseThreeP2)
		logAnalytics(24, "BEGIN_PHASE_THREE")
		PhaseThree.Intro()
		
	elseif event == "BOSS_FINISHED" then
		logAnalytics(28, "BOSS_COMPLETE")
		PhaseThree.BossFinished()
		
	elseif event == "ENDING" then
		PhaseThree.GoodEnding()
	end
end)