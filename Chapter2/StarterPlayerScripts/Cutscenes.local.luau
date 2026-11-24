local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local SOUND_MODULE = require(ReplicatedStorage.SoundModule)
local player = Players.LocalPlayer
local playerGUI = player.PlayerGui

local camera = workspace.CurrentCamera
local CUTSCENE_CAMERAS = workspace:WaitForChild("CutsceneCameras")
local CUTSCENE_GUI = playerGUI:WaitForChild("CutsceneGui")
local transitionFrame = CUTSCENE_GUI:WaitForChild("Transition")
local SCREEN_SHAKE = require(script.Parent.ScreenShake)

local events = ReplicatedStorage:WaitForChild("Events")
local CutsceneEvent = events:WaitForChild("CutsceneEvent")
local RESET_CUTSCENE = events:WaitForChild("ResetCutscene")
local TOGGLE_EVENT = events:WaitForChild("ToggleEvent")
local DeathScreenRemote = events:WaitForChild("DeathScreen")

local SCRIPTABLE =  Enum.CameraType.Scriptable

local CHESTER = workspace.CampInstructor
local camTween : Tween
local connection
local content

local function restoreCamera()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = hum
end


local function dialogueText(text, waitTime, chester)
	if chester then
		playerGUI.StoryGUI.DialogueFrame.Visible = true
		for i = 1, #text do
			playerGUI.StoryGUI.DialogueFrame.TextInfo.Text = string.sub(text, 1, i)
			task.wait(0.05)
			script.TextTick:Play()
		end		
		task.wait(waitTime)
		playerGUI.StoryGUI.DialogueFrame.Visible = false
	else
		playerGUI.StoryGUI.VillianFrame.Visible = true
		for i = 1, #text do
			playerGUI.StoryGUI.VillianFrame.TextInfo.Text = string.sub(text, 1, i)
			task.wait(0.05)
			script.TextTick:Play()
		end	
		task.wait(waitTime)
		playerGUI.StoryGUI.VillianFrame.Visible = false
	end
end

local function playerDialogueText(text)
	local playerDialogueGUI = playerGUI.StoryGUI.PlayerFrame
	local success, content = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size180x180)
	end)

	playerDialogueGUI.PlayerImageFrame.PlayerImg.Image = content
	playerDialogueGUI.PlayerImageFrame.PlayerName.Text = player.Name
	playerDialogueGUI.Visible = true

	for i = 1, #text do
		playerDialogueGUI.TextInfo.Text = string.sub(text, 1, i)
		task.wait(0.04)
		script.TextTick:Play()
	end
end

-- !!! method yields main thread when called
local function Transition(length, event)
	transitionFrame.BackgroundTransparency = 1
	transitionFrame.Visible = true
	local transitionInfo = TweenInfo.new(length, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true)
	local tween = TweenService:Create(transitionFrame, transitionInfo, {BackgroundTransparency = 0})
	tween:Play()
	task.wait(length)
	tween:Pause()
	if length <= 1 then 
		task.wait(length * 2)
	else
		task.wait(length / 2)
	end

	if event then
		restoreCamera()
	end

	tween:Play()
	task.wait(length)
	transitionFrame.Visible = false
end

local function disableCoreGUI()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	playerGUI.ShopGUI.ToggleShop.Visible = false
	playerGUI.ShopGUI.MainFrame.Visible = false
	for i, frame in playerGUI.GamePassGUI:GetChildren() do
		if frame.Visible then
			frame.Visible = false
		end
	end
end

local function enableCoreGUI()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	playerGUI.ShopGUI.ToggleShop.Visible = true
end

local dropTrack
local obbyTrack

CutsceneEvent.OnClientEvent:Connect(function(cutscene)
	if not player:GetAttribute("Alive") then return end 

	if cutscene == "SECURITY_INTRO" then
		camera.CameraType = SCRIPTABLE
		camera.CFrame = CUTSCENE_CAMERAS.SecurityCams.SecurityCamOne.CFrame

		TweenService:Create(camera, TweenInfo.new(6), {CFrame = CUTSCENE_CAMERAS.SecurityCams.SecurityCamTwo.CFrame}):Play()
		task.wait(7)

		restoreCamera()

	elseif cutscene == "SECURITY_GUARD" then	
		task.spawn(function()
			SOUND_MODULE.ActionSound("rbxassetid://28257433", 0.3, 1.2)
		end)
		task.delay(2, function()
			transitionFrame.Visible = false
		end)
		Transition(0.3)

	elseif cutscene == "SECURITY_DOOR" then
		camera.CameraType = SCRIPTABLE
		camTween = TweenService:Create(camera, TweenInfo.new(2), {CFrame = CUTSCENE_CAMERAS.SecurityCams.DoorCam.CFrame}):Play()
		task.wait(3.5)
		camTween = TweenService:Create(camera, TweenInfo.new(1), {CFrame = player.Character.Head.CFrame}):Play()
		task.wait(1)
		restoreCamera()
		camTween = nil

	elseif cutscene == "SECURITY_FINISHED" then
		camera.CameraType = SCRIPTABLE
		camera.CFrame = CUTSCENE_CAMERAS.SecurityCams.SecurityExitCam.CFrame
		task.wait(1)
		TweenService:Create(workspace.SecurityRoom.SecurityDoor, TweenInfo.new(3), {CFrame = workspace.SecurityRoom.SecurityDoor.CFrame * CFrame.new(0, 35, 0)}):Play()
		SOUND_MODULE.ActionSound("rbxassetid://833871080", 0.4, 0.6)
		task.wait(6)
		Transition(2.5, true)
		task.delay(10, function()
			transitionFrame.Visible = false
		end)
		restoreCamera()
	

		-- preloading anim
		local dropAnim = Instance.new("Animation")
		dropAnim.AnimationId = "rbxassetid://17631254870"
		dropTrack = CHESTER.Humanoid.Animator:LoadAnimation(dropAnim)		

	elseif cutscene == "CHESTER_DROP" then

		SOUND_MODULE.ActionSound("rbxassetid://9114395530")
		dropTrack:Play()
		dropTrack:AdjustSpeed(3)
		dropTrack:GetMarkerReachedSignal("Lay"):Connect(function()
			dropTrack:AdjustSpeed(0)
		end)

	elseif cutscene == "CHESTER_RISE" then
		dropTrack:AdjustSpeed(2.5)
		task.wait(10)
		dropTrack = nil
		SOUND_MODULE.ActionSound("rbxassetid://833871080", 0.2)

	elseif cutscene == "OBBY_DOOR" then
		local obbyBorder = workspace.StoryBorders.ObbyEntrance
		TweenService:Create(obbyBorder, TweenInfo.new(0.5), {CFrame = obbyBorder.CFrame * CFrame.new(0, -12, 0)}):Play()
		SOUND_MODULE.ActionSound("rbxassetid://9116725218", nil, 0.6)

		-- preload obbyTrack
		local obbyAnim = Instance.new("Animation")
		obbyAnim.AnimationId = "rbxassetid://108784165892805"
		obbyTrack = CHESTER.Humanoid.Animator:LoadAnimation(obbyAnim)

	elseif cutscene == "CHESTER_OBBY" then

		obbyTrack:Play()
		SOUND_MODULE.ActionSound("rbxassetid://87679579947858", 0.1, 0.5)

		obbyTrack:GetMarkerReachedSignal("Dialogue"):Connect(function()
			obbyTrack:AdjustSpeed(0)
			task.wait(2)
			obbyTrack:AdjustSpeed(0.5)
		end)

		-------------------- PHASE TWO ----------------------------------------

	elseif cutscene == "PHASE_TWO" then
		task.delay(8, function()
			transitionFrame.Visible = false
		end)
		Transition(2)
	

	elseif cutscene == "VILLIAN_INTRO" then
		task.spawn(function()
			for i = 0, 1 do
				SOUND_MODULE.ActionSound("rbxassetid://1065138275", 0.9, 0.8)
				for i = 0, 3 do 
					if i == 2 then SCREEN_SHAKE.Shake(player.Character, 0.3, 120) task.wait(0.2) end	
					SCREEN_SHAKE.Shake(player.Character, 0.3, 120)
					task.wait(1.58)
				end	
			end
		end)

		task.wait(6)
		TweenService:Create(game.Lighting.Atmosphere, TweenInfo.new(3), {Density = 0.55}):Play()

	elseif cutscene == "VILLIAN_ANGER" then	
		SOUND_MODULE.ActionSound("rbxassetid://9120059083")
		for i = 0, 7 do
			SOUND_MODULE.ActionSound("rbxassetid://99014558953730")
			SCREEN_SHAKE.Shake(player.Character, 0.3, 80)
			task.wait(0.6)
		end

	elseif cutscene == "COURTYARD_ESCAPE" then
		SOUND_MODULE.ActionSound("rbxassetid://9041754040")
		for i = 0, 4 do
			SOUND_MODULE.ActionSound("rbxassetid://9114589190")
			SCREEN_SHAKE.Shake(player.Character, 0.3, 150)
			task.wait(2)
		end

		-------------------- PHASE THREE ----------------------------------------

	elseif cutscene == "SETUP_FAKE_ESCAPE" then
		task.delay(0.5, function()
			local blur = Instance.new("BlurEffect")
			blur.Size = 3
			blur.Enabled = false
			blur.Name = "Blur"
			blur.Parent = Lighting

			local colorCorrection = Instance.new("ColorCorrectionEffect")
			colorCorrection.Brightness = 0
			colorCorrection.Contrast = 0
			colorCorrection.TintColor = Color3.fromRGB(255,255,255)
			colorCorrection.Saturation = 0
			colorCorrection.Name = "ColorCorrection"
			colorCorrection.Parent = Lighting

			Lighting.Ambient = Color3.fromRGB(0,0,0)
			Lighting.Atmosphere.Density = 0.8
			Lighting.Atmosphere.Offset = 1
			Lighting.Atmosphere.Color = Color3.fromRGB(178, 60, 38)
			Lighting.Atmosphere.Decay = Color3.fromRGB(146, 89, 61)
			Lighting.Brightness = 1
		end)
		Transition(1.5)


	elseif cutscene == "FAKE_ESCAPE" then
		disableCoreGUI()
		transitionFrame.Visible = false
		camera.CameraType = SCRIPTABLE
		local atmosphere = Lighting.Atmosphere
		local colorCorrection = Lighting.ColorCorrection
		
		if not colorCorrection then
		 	colorCorrection = Instance.new("ColorCorrectionEffect")
			colorCorrection.Brightness = 0
			colorCorrection.Contrast = 0
			colorCorrection.TintColor = Color3.fromRGB(255,255,255)
			colorCorrection.Saturation = 0
			colorCorrection.Name = "ColorCorrection"
			colorCorrection.Parent = Lighting
		end

		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://16093364613"
		local villianTrack = workspace.Villian.Humanoid.Animator:LoadAnimation(anim)
		local grabTrack = workspace.CampInstructor.Humanoid.Animator:LoadAnimation(workspace.CampInstructor.Configuration.Grab)

		local lever = workspace.Cave.SecondArea.EscapeLever
		local door = workspace.ExitDoor


		camera.CFrame = CUTSCENE_CAMERAS.FakeEscape.FakeEscapeCamera.CFrame
		camTween = TweenService:Create(camera, TweenInfo.new(5), {CFrame = CUTSCENE_CAMERAS.FakeEscape.FakeEscapeCameraTwo.CFrame}):Play()
		grabTrack:Play()
		grabTrack:AdjustSpeed(0.5)

		task.wait(0.5)	

		TweenService:Create(lever.Lever, TweenInfo.new(2), {CFrame = lever:WaitForChild("LeverGoal").CFrame}):Play()
		SOUND_MODULE.ActionSound("rbxassetid://9125626281")

		task.wait(0.5)

		TweenService:Create(door, TweenInfo.new(3), {CFrame = door.CFrame * CFrame.new(0,16, 0)}):Play()

		task.wait(3)

		local colorCorrectProperties = {Brightness = -0.1, TintColor = Color3.fromRGB(236, 19, 13), Saturation = -1, Contrast = 0.5}
		Lighting.Blur.Enabled = true
		local atmosphereProperties = {Glare = 5, Haze = 5}
		camTween = TweenService:Create(camera, TweenInfo.new(2), {CFrame = CUTSCENE_CAMERAS.FakeEscape.FakeEscapeCameraThree.CFrame}):Play()
		TweenService:Create(Lighting.ColorCorrection, TweenInfo.new(4), colorCorrectProperties):Play()

		task.wait(2)

		TweenService:Create(atmosphere, TweenInfo.new(2), atmosphereProperties):Play()

		task.wait(2)

		SOUND_MODULE.ActionSound("rbxassetid://9043338697", 0.7)
		local lightTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut, 1, true, 0.1)
		TweenService:Create(Lighting.ColorCorrection, lightTweenInfo, {Saturation = 1}):Play()

		villianTrack:Play()
		villianTrack:AdjustSpeed(0.4)		
		villianTrack:GetMarkerReachedSignal("WAIT"):Connect(function()
			villianTrack:AdjustSpeed(0.05)
			colorCorrection.Saturation = 1
			lightTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut)
			task.wait(0.4)
			TweenService:Create(colorCorrection, lightTweenInfo, {Saturation = -1}):Play()
		end)

		-- !!! setup for elevator cutscene
		task.delay(2, function()
			Transition(3)
		end)

		task.wait(3)

		atmosphere.Decay = Color3.fromRGB(252, 32, 20)
		atmosphere.Color = Color3.fromRGB(0,0,0)
		atmosphere.Density = 1
		atmosphere.Haze = 2
		atmosphere.Glare = 0
		atmosphere.Offset = 0

		colorCorrection.Brightness = -0.05
		colorCorrection.Contrast = 0.3
		colorCorrection.Saturation = 0
		colorCorrection.TintColor = Color3.fromRGB(240,240,240)

		restoreCamera()
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		enableCoreGUI()

	elseif cutscene == "ELEVATOR" then

		local cheeringNPCFolder = Instance.new("Folder", workspace)

		playerGUI.StoryGUI.BlackoutFrame.Visible = true
		local elevator = workspace.Elevator
		local storyCandle = elevator.ElevatorCandles.StoryCandle

		local cheeringAnim1 = Instance.new("Animation")
		local cheeringAnim2 = Instance.new("Animation")
		local drumAnim = Instance.new("Animation")
		cheeringAnim1.AnimationId = "rbxassetid://15768686971"
		cheeringAnim2.AnimationId = "rbxassetid://15573365290"
		drumAnim.AnimationId = "rbxassetid://97118119709867"
		local cheeringAnims = {cheeringAnim1, cheeringAnim2}

		local cheeringSound = Instance.new("Sound")
		cheeringSound.SoundId = "rbxassetid://91461881930918"
		cheeringSound.Looped = true
		cheeringSound.Volume = 0.7
		cheeringSound.PlaybackSpeed = 0.8
		cheeringSound.RollOffMaxDistance = 50
		cheeringSound.Parent = elevator.SoundPart

		TweenService:Create(Lighting.Atmosphere, TweenInfo.new(0.5), {Density = 0.6, Glare = 9}):Play()
		workspace.Lights.ElevatorLights.LightPart.SurfaceLight.Enabled = true

		for _, npcSpawn in elevator.NPCSpawns.NormalSpawns:GetChildren() do
			local clone = ReplicatedStorage.EventObjects.ELEVATORNPC:Clone()
			clone.PrimaryPart:PivotTo(npcSpawn.CFrame)
			clone.Parent = cheeringNPCFolder
			local track = clone.Humanoid.Animator:LoadAnimation(cheeringAnims[math.random(1, #cheeringAnims)])
			track.Looped = true
			track:Play()	
		end

		for _, drumSpawn in elevator.NPCSpawns.DrumSpawns:GetChildren() do
			local drumClone = ReplicatedStorage.EventObjects.DRUMNPC:Clone()
			drumClone.PrimaryPart:PivotTo(drumSpawn.CFrame * CFrame.new(0, 2, 0))
			drumClone.Parent = cheeringNPCFolder
			local drumTrack = drumClone.Humanoid.Animator:LoadAnimation(drumAnim)
			drumTrack.Looped = true
			drumTrack:Play()
		end

		task.wait(5)

		SOUND_MODULE.SetAudio("BOSS", "rbxassetid://1843640242", 0.25)
		transitionFrame.Visible = false

		task.wait(6)

		cheeringSound:Play()
		SOUND_MODULE.SetAudio("AMBIENCE", "rbxassetid://1842999580", 0.6, false, nil, 1, 9)
		SOUND_MODULE.ActionSound("rbxassetid://1846886137", 0.4)
		playerGUI.StoryGUI.BlackoutFrame.Visible = false

		task.wait(2.5)

		SOUND_MODULE.ActionSound("rbxassetid://4657340119", 1, 0.8)
		SOUND_MODULE.ActionSound("rbxassetid://2899879663", 0.8, 0.52)

		task.wait(18)

		SOUND_MODULE.ActionSound("rbxassetid://4657340119", 1, 0.8)
		TweenService:Create(elevator.BossEntrance.Bars, TweenInfo.new(6), {CFrame = elevator.BossEntrance.Bars.CFrame * CFrame.new(0, 22, 0)}):Play()
		player.CameraMode = Enum.CameraMode.Classic
		cheeringNPCFolder:Destroy()
		cheeringSound:Destroy()

	elseif cutscene == "BOSS" then
		-- bug occuring here keeps freezing
		disableCoreGUI()

		local BOSS_CAMERAS = CUTSCENE_CAMERAS.BossCams
		local BOSS = ReplicatedStorage.EventObjects.CutsceneBoss

		local idleAnim = Instance.new("Animation")
		local bossAnimation = Instance.new("Animation")

		bossAnimation.AnimationId = "rbxassetid://72038105326074"
		idleAnim.AnimationId = "rbxassetid://10921301576"

		local idleTrack = BOSS.Humanoid.Animator:LoadAnimation(idleAnim)
		local bossTrack = BOSS.Humanoid.Animator:LoadAnimation(bossAnimation)

		BOSS.PrimaryPart:PivotTo(workspace.CutsceneBossSpawn.CFrame * CFrame.new(0, 8, 0))
		BOSS.Parent = workspace

		idleTrack.Priority = Enum.AnimationPriority.Idle
		idleTrack:Play()

		camera.CameraType = SCRIPTABLE
		camera.CFrame = BOSS_CAMERAS.One.CFrame
		camera.FieldOfView = 80
		TweenService:Create(camera, TweenInfo.new(9), {CFrame = BOSS_CAMERAS.Two.CFrame}):Play()

		task.wait(3)
		task.delay(1, function()
			Lighting.Atmosphere.Density = 0.8
			Lighting.Ambient = Color3.fromRGB(88, 12, 10)
			Lighting.Atmosphere.Color = Color3.fromRGB(40,40,40)
			Lighting.Atmosphere.Glare = 0
			Lighting.ColorCorrection.Brightness = 0
			Lighting.ColorCorrection.Contrast = 0
			Lighting.Blur.Enabled = false

		end)

		task.spawn(Transition, 3)

		SOUND_MODULE.SetAudio("AMBIENCE", "rbxassetid://9112775175", 0.5, false, 2)
	
		task.wait(4)

		camera.CFrame = BOSS_CAMERAS.Three.CFrame
		local camFour = BOSS_CAMERAS:WaitForChild("Four", 2)
		SOUND_MODULE.ActionSound("rbxassetid://224339308", 0.5, 0.8)
		SOUND_MODULE.ChangeVolume("BOSS", 0, 3)
		
		if camFour then
			TweenService:Create(camera, TweenInfo.new(8), {CFrame = BOSS_CAMERAS.Four.CFrame, FieldOfView = 65}):Play()
		else
			task.wait(8)
		end
	
		transitionFrame.Visible = false
		dialogueText("Welcome intruders...", 4)	

		task.delay(11, function()
			SOUND_MODULE.ActionSound("rbxassetid://1848124042")
		end)

		dialogueText("You went through all this trouble to steal these candles, I figured it was only fair for you all to witness the grand summoning", 4)

		bossTrack:Play()
		bossTrack:AdjustSpeed(0.25)

		task.wait(1.5)

		camera.CFrame = BOSS_CAMERAS.CandleCam.CFrame
		TweenService:Create(camera, TweenInfo.new(4.5), {CFrame = BOSS_CAMERAS.CandleCamTwo.CFrame}):Play()

		bossTrack:GetMarkerReachedSignal("CandleTouched"):Connect(function()

			local cutsceneCandleVFX = workspace.BossCutsceneCandle.CutsceneVFX
			BOSS.RightHand.FIRE.Flame.Enabled = true
			BOSS.RightHand.FIRE.GLOW.Enabled = true
			SOUND_MODULE.ActionSound("rbxassetid://3518146972")
			SOUND_MODULE.ActionSound("rbxassetid://9116395085")
			SOUND_MODULE.ActionSound("rbxassetid://5862482798")

			cutsceneCandleVFX.PotentialTP.Enabled = true
			cutsceneCandleVFX.Ground.Enabled = true
			cutsceneCandleVFX.Ritual.Enabled = true

			task.wait(1)
			bossTrack:AdjustSpeed(0.2)
		end)

		task.wait(4.5)

		TweenService:Create(camera, TweenInfo.new(3), {CFrame = BOSS_CAMERAS.CandleCamThree.CFrame}):Play()

		task.wait(1)

		bossTrack:GetMarkerReachedSignal("Summon"):Connect(function()
			bossTrack:AdjustSpeed(0.5)
		end)

		bossTrack:GetMarkerReachedSignal("Slowdown"):Connect(function()
			bossTrack:AdjustSpeed(0.07)
			SOUND_MODULE.ActionSound("rbxassetid://113216405853964")
			SOUND_MODULE.ActionSound("rbxassetid://9066063881", 1, 0.9)

			for i, particle in workspace.BossCutsceneCandle.CutsceneVFX:GetChildren() do
				particle.Enabled = true
				task.delay(1, function()
					particle.Enabled = false
				end)
			end

			for i, particle in BOSS.HumanoidRootPart.CutsceneVFX:GetChildren() do
				particle.Enabled = true
				task.delay(1, function()
					particle.Enabled = false
				end)
			end

			TweenService:Create(camera, TweenInfo.new(1), {FieldOfView = 110}):Play()
			local originalCFrame = camera.CFrame
			for i = 1, 130 do -- !!! shake camera
				local offset = math.random(-400, 400) / (i * 20)
				camera.CFrame = camera.CFrame * CFrame.new(offset, offset, offset)
				task.wait()
				camera.CFrame = originalCFrame
			end
			
			camera.CFrame = originalCFrame
		end)

		task.wait(2.1)

		camera.CFrame = BOSS_CAMERAS.Eruption.CFrame

		task.wait(2.1)

		TweenService:Create(camera, TweenInfo.new(4.5, Enum.EasingStyle.Circular, Enum.EasingDirection.In), {CFrame = camera.CFrame * CFrame.new(0, 0, -5)}):Play()

		task.wait(4.5)

		camera.CFrame = BOSS_CAMERAS.BossEyes.CFrame
		TweenService:Create(camera, TweenInfo.new(4, Enum.EasingStyle.Linear), {CFrame = BOSS_CAMERAS.BossEyesTwo.CFrame}):Play()

		task.wait(2)

		SOUND_MODULE.ActionSound("rbxassetid://5862482798")
		SOUND_MODULE.ActionSound("rbxassetid://3518146972", nil, 0.8)

		BOSS.Head.LeftFireEye.Flame.Enabled = true
		BOSS.Head.RightFireEye.Flame.Enabled = true
		BOSS.Head.RightFireEye.FIRE.Enabled = true
		BOSS.Head.LeftFireEye.FIRE.Enabled = true

		bossAnimation.AnimationId = "rbxassetid://71145673906015"
		bossTrack = BOSS.Humanoid.Animator:LoadAnimation(bossAnimation)

		dialogueText("Now then intruders, Why don't I burn you all into ashes!", 2)

		task.delay(2.5, function()
			SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://103001514908606")
		end)

		BOSS.LeftHand.FIRE.Flame.Enabled = true
		BOSS.LeftHand.FIRE.GLOW.Enabled = true

		bossTrack:Play()
		bossTrack:AdjustSpeed(0.2)
		TweenService:Create(camera, TweenInfo.new(9.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {CFrame = BOSS_CAMERAS.Six.CFrame, FieldOfView = 65}):Play()

		task.wait(3)

		TweenService:Create(Lighting.Atmosphere, TweenInfo.new(4), {Density = 0.4}):Play()

		task.wait(5)

		player.Character.Humanoid.WalkSpeed = 16
		player.Character.Humanoid.JumpHeight = 7.2


		task.delay(1, function()
			restoreCamera()
			camera.FieldOfView = 70
			enableCoreGUI()
			BOSS.Parent = ReplicatedStorage
			task.wait(1) -- !!! to make sure server boss and cutscene boss don't collide
			TOGGLE_EVENT:FireServer("BOSS")
			for i, light in workspace.Lights.BossLights:GetChildren() do
				light.PointLight.Enabled = true
			end

		end)
		task.delay(8, function()
			transitionFrame.Visible = false
		end)
		Transition(2)
	
		playerGUI.ShopGUI.ToggleShop.Visible = true


		task.delay(55, function()
			SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1842942838", 0.5, true, 1)
		end)

	elseif cutscene == "NO_REVIVE" then
		local bossMessage = playerGUI.BossGUI.BossMessage
		bossMessage.TextInfo.Text = "You can no longer revive, good luck"
		bossMessage.Visible = true	
		task.wait(5)
		bossMessage.Visible = false	

	elseif cutscene == "BOSS_FINISHED" then

		disableCoreGUI()
		task.delay(8, function()
			transitionFrame.Visible = false
		end)
		task.delay(1, Transition, 2)
		playerGUI.BossHearts.Enabled = false
		task.wait(2)

		SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1838457617", nil, nil, 2)
		camera.CameraType = SCRIPTABLE
		camera.CFrame = workspace.CutsceneCameras.BossCams.Finished.CFrame

		task.wait(1.5)

		local boss = workspace.Boss
		local finishedAnim = Instance.new("Animation")
		finishedAnim.AnimationId = "rbxassetid://117818884729698"
		local finishedTrack = boss.Humanoid.Animator:LoadAnimation(finishedAnim)

		finishedTrack:Play()
		finishedTrack:AdjustSpeed(0.5)

		finishedTrack:GetMarkerReachedSignal("GroundHit"):Connect(function()
			SOUND_MODULE.ActionSound("rbxassetid://77072623407707", 0.3, 0.6)
		end)	


		finishedTrack:GetMarkerReachedSignal("Idle"):Connect(function()

			finishedTrack:AdjustSpeed(0.05)

			dialogueText("How was I defeated...", 4)

			dialogueText("My grand summoning... burned... burned away...", 4)

			dialogueText("Please forgive me for this", 10)
		end)



	elseif cutscene == "No" then

		local boss = workspace.Boss
		SOUND_MODULE.ActionSound("rbxassetid://9125635285", nil, 0.6)

		boss.HumanoidRootPart.FinishedVFX.Specs.Enabled = true
		boss.HumanoidRootPart.FinishedVFX.SummonEffect.Enabled = true

		task.delay(3, function()
			for i, part in game.CollectionService:GetTagged("TeleportPart") do
				TweenService:Create(part, TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
			end
		end)

		task.wait(5)
		boss.HumanoidRootPart.FinishedVFX.Specs.Enabled = false
		boss.HumanoidRootPart.FinishedVFX.SummonEffect.Enabled = false
		for i, particle in workspace.BossCutsceneCandle.Particles:GetChildren() do
			particle.Enabled = false
		end

		task.wait(5)

		camera.CFrame = workspace.CutsceneCameras.BossCams.Chester.CFrame
		SOUND_MODULE.ChangeVolume("AMBIENCE", 0, 1)
		task.wait(1)

		dialogueText("Great job folks! Y'all beat him and saved me!", 3, true)
		dialogueText("I owe my life to each and everyone of you. Thank you.", 5, true)

		task.delay(2, function()
			restoreCamera()
			enableCoreGUI()
		end)

	elseif cutscene == "Yes" then

		local boss = workspace.Boss
		local badEndingCams = CUTSCENE_CAMERAS.BadEndingCams
		local Cage = workspace.BossRoom.ChesterCage
		local bossBeamAnim = Instance.new("Animation")
		bossBeamAnim.AnimationId = "rbxassetid://112340851680174"
		dialogueText("My camp squad said we'll save you", 3, true)


		local badCandles = ReplicatedStorage.EventObjects.BadEndingCandles
		badCandles.Parent = workspace
		dialogueText("Please light up my life candles", 3)

		camera.CFrame = badEndingCams.LifeCandles.CFrame

		task.wait(1)

		SOUND_MODULE.ActionSound("rbxassetid://4403634269")
		for i, candle in badCandles:GetChildren() do
			candle.Particles.Flame.Enabled = true
			candle.Particles.GLOW.Enabled = true
		end

		task.wait(4)
		task.spawn(function()
			SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1843789930", nil, nil, 3)
		end)

		for i, candle in badCandles:GetChildren() do
			candle.Particles.Flame.Enabled = true
			candle.Particles.Flame.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
			candle.Particles.GLOW.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
			SOUND_MODULE.ActionSound("rbxassetid://9125402735", 2, 0.7)
			task.wait(1)
		end

		camera.CFrame = CUTSCENE_CAMERAS.BossCams.Eruption.CFrame
		local bossCandle = workspace.BossCutsceneCandle
		bossCandle.BadParticles.Flame.Enabled = true
		local bossBeamTrack = boss.Humanoid.Animator:LoadAnimation(bossBeamAnim)
		task.wait(0.5)
		dialogueText("Well... it seems I still have intruders I need to get rid of", 2)

		task.spawn(function()
			dialogueText("Starting with you", 2)
		end)

		task.wait(1)

		bossBeamTrack:Play()
		bossBeamTrack:AdjustSpeed(0.5)
		camera.CFrame = badEndingCams.BeamCam1.CFrame
		bossBeamTrack:GetMarkerReachedSignal("Beam"):Connect(function()
			TweenService:Create(camera, TweenInfo.new(0.5), {CFrame = badEndingCams.BeamCam2.CFrame}):Play()

			Cage.BossStone.FireBeam.Enabled = true
			Cage.BossStone.LightBeam.Enabled = true

			task.wait(0.5)

			SOUND_MODULE.ActionSound("rbxassetid://113216405853964")
			SOUND_MODULE.ActionSound("rbxassetid://9066063881", 1, 0.9)
			task.spawn(function()
				for i = 1, 100 do -- !!! shake camera
					local offset = math.random(-100, 100) / (i * 20)
					camera.CFrame = camera.CFrame * CFrame.new(offset, offset, offset)
					task.wait()
				end
			end)

			Cage.default.ExplosionFX.Fire.Enabled = true
			Cage.default.ExplosionFX.Glows.Enabled = true
			CHESTER:Destroy()
			task.wait(2)

			Cage.BossStone.FireBeam.Enabled = false
			Cage.BossStone.LightBeam.Enabled = false
			Cage.default.ExplosionFX.Fire.Enabled = false
			Cage.default.ExplosionFX.Glows.Enabled = false

			task.wait(3)

			TweenService:Create(camera, TweenInfo.new(3), {CFrame = badEndingCams.BossEyes.CFrame}):Play()
			for i, child in boss.Head:GetChildren() do
				if child.Name == "EyeParticle" then
					child.FIRE.Enabled = true
					child.Flame.Enabled = true
				end
			end
			dialogueText("Run...", 2)

			task.spawn(function()
				SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1845205138", 0.8, nil, 1.5)
			end)
			dialogueText("Run for your lives...", 2)
			TOGGLE_EVENT:FireServer("BAD_ENDING_CHASE")
			task.delay(3, function()
				local bossMessage = playerGUI.BossGUI.BossMessage
				bossMessage.TextInfo.Text = "Follow the green candles!"
				bossMessage.Visible = true	
				task.wait(5)
				bossMessage.Visible = false	
			end)
		end)

	elseif cutscene == "BOSS_CHASE" then

		SCREEN_SHAKE.Shake(player.Character, 14, 150)
		TweenService:Create(camera, TweenInfo.new(1), {CFrame = player.Character.Head.CFrame}):Play()
		task.wait(1)
		restoreCamera()
		

	elseif cutscene == "FOREST" then

		task.delay(1, function()
			SOUND_MODULE.SetAudio("AMBIENCE", "rbxassetid://179507208", 0.5, true, 2)

			Lighting.Ambient = Color3.fromRGB(26, 28, 86)
			Lighting.OutdoorAmbient = Color3.fromRGB(50,50,50)
			Lighting.Brightness = 1.3
			Lighting.GlobalShadows = false
			Lighting.ExposureCompensation = 0.5
			Lighting.Sky.StarCount = 0

			Lighting.Atmosphere.Density = 0.6
			Lighting.Atmosphere.Color = Color3.fromRGB(18, 18, 41)
			Lighting.Atmosphere.Decay = Color3.fromRGB(0, 0, 0)
			Lighting.Atmosphere.Haze = 5
			Lighting.Atmosphere.Glare = 0
		end)
		task.delay(10, function()
			transitionFrame.Visible = false
		end)
		Transition(3)

	elseif cutscene == "BAD_ENDING" then
		--connection:Disconnect()

		disableCoreGUI()
		local finalEndingCams = CUTSCENE_CAMERAS.FinalEndCams
		local finalRoomCandles = workspace.BossRoom.BossChase.FinalRoom.Candles
		local cultFace = workspace.BossRoom.BossChase.FinalRoom.CultFace
		local badEndingObjects = ReplicatedStorage.BadEndingCutscene
		local endingCart = workspace.EndingCart


		camera.CameraType = SCRIPTABLE
		TweenService:Create(camera, TweenInfo.new(1), {CFrame = finalEndingCams.Cam1.CFrame}):Play()
		SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1840020699", 0.5, nil, 2, 0.6)
		task.wait(1)
		TweenService:Create(camera, TweenInfo.new(7, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = finalEndingCams.Cam2.CFrame}):Play()


		for i, candle in finalRoomCandles:GetChildren() do
			candle.Particles.GLOW.Enabled = true
			candle.Particles.Flame.Enabled = true
			task.wait(0.3)
			if i % 2 == 0 then SOUND_MODULE.ActionSound("rbxassetid://4403634269", 0.5) end	
		end

		task.wait(1)
		task.delay(1, Transition, 3)
		SOUND_MODULE.ActionSound("rbxassetid://5862482798")

		for i, particles in cultFace:GetChildren() do
			particles.FIRE.Enabled = true
			particles.Flame.Enabled = true
		end

		local sitAnim = Instance.new("Animation")
		sitAnim.AnimationId = "rbxassetid://95128526244610"
		local sitAnim2 = Instance.new("Animation")
		sitAnim2.AnimationId = "rbxassetid://120807830093327"
		local sitAnims = {sitAnim, sitAnim2}

		SOUND_MODULE.SetAudio("AMBIENCE", "rbxassetid://179507208", 0.5, true, 2)

		task.delay(4, function()
			local endingCartSeats = endingCart.CartSeats
			camera.CFrame = finalEndingCams.Cam3.CFrame
			for i = 1, #endingCartSeats:GetChildren() do
				if i % 3 == 0 then continue end
				local weld = Instance.new("WeldConstraint")
				local seat : Seat= endingCartSeats[i]	
				local endingCamper = badEndingObjects.EndingCamper:Clone()
				endingCamper.Parent = workspace
				endingCamper:PivotTo(seat.CFrame)
				weld.Part0 = seat
				weld.Part1 = endingCamper.PrimaryPart
				weld.Parent = endingCamper
				local ranAnim = sitAnims[math.random(1, #sitAnims)]
				endingCamper.Humanoid.Animator:LoadAnimation(ranAnim):Play()
			end
		end)
		ReplicatedStorage.CartCandle.Parent = workspace
		
		task.delay(6, function()
			playerDialogueText("Long story short, we ended up joining the cultists!")
			task.wait(6.5)
			playerDialogueText("They offered us to join, and since we had nowhere to go, we had to accept!")
			task.wait(5)
			playerDialogueText("We finally learned the truth about where the candles come from...")
			task.wait(5)
			playerDialogueText("Come on.. lets go give a warm welcome to our new campers...") 
			task.wait(3)
			playerGUI.StoryGUI.PlayerFrame.Visible = false
			
			task.spawn(function()
				SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1840684529", 1, true, 0.5)
			end)
			TweenService:Create(camera, TweenInfo.new(16), {CFrame = finalEndingCams.Final.CFrame}):Play()
			local endingScreen = playerGUI.EndingScreen.Frame
			endingScreen.Visible = true
			TweenService:Create(endingScreen.Candles, TweenInfo.new(5, Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
			
			task.wait(10)
			endingScreen.Return.Visible = true
			endingScreen.Return.LobbyButton.Activated:Connect(function()
				DeathScreenRemote:FireServer("LOBBY")
			end)
		end)
		
		task.delay(6, function()
			
			local badEndingNPCSpawns = workspace.BadEnding.EndingNPCSpawns
			for i, npcSpawn in badEndingNPCSpawns:GetChildren() do
				local npc = badEndingObjects.CutsceneNPC:Clone()
				npc:PivotTo(npcSpawn.CFrame)
				npc.Parent = workspace
			end

			for i, wheel in endingCart.Wheels:GetChildren() do
				task.spawn(function()
					for i = 1, 500 do
						wheel.Orientation = Vector3.new(i % 360 * -3, 90, 0)
						task.wait()
					end
				end)
			end


			SOUND_MODULE.SetAudio("BOSS", "rbxassetid://6560398360", 2, 1.2)
			SOUND_MODULE.ChangeVolume("BOSS", 0, 8)
			TweenService:Create(camera, TweenInfo.new(8), {CFrame = finalEndingCams.Cam4.CFrame}):Play()
			TweenService:Create(endingCart.PrimaryPart, TweenInfo.new(30), {CFrame = endingCart.PrimaryPart.CFrame * CFrame.new(0, 0, -200)}):Play()
			task.wait(9)
			TweenService:Create(camera, TweenInfo.new(4), {CFrame = finalEndingCams.Cam5.CFrame}):Play()
		end)	




	elseif cutscene == "THE_END" then
		disableCoreGUI()

		local cartTween
		local END_CAMS = CUTSCENE_CAMERAS.EndCams
		local endingCart = workspace.EndingCart
		local waveAnim = Instance.new("Animation")
		waveAnim.AnimationId = "http://www.roblox.com/asset/?id=10714362852"
		local waveTrack = CHESTER.Humanoid.Animator:LoadAnimation(waveAnim)
		local grabTrack = CHESTER.Humanoid.Animator:LoadAnimation(CHESTER.Configuration.Grab)

		task.delay(1, function()
			endingCart.MainCartBody.PointLight.Enabled = true
			camera.CameraType = SCRIPTABLE
			camera.CFrame = END_CAMS.FirstCam.CFrame
			SOUND_MODULE.SetAudio("MUSIC", "rbxassetid://1836589492", nil, true, 1)
		end)
		Transition(1.5)	

		task.wait(1)

		grabTrack:Play()
		grabTrack:AdjustSpeed(0.6)
		local cartCandle = ReplicatedStorage.CartCandle
		cartCandle.Parent = workspace
		endingCart.CartCandle.CandleWeld.Enabled = true
		SOUND_MODULE.ActionSound("rbxassetid://77072623407707")

		task.wait(2)

		camera.CFrame = END_CAMS.WheelCamOne.CFrame 
		local cartTweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		SOUND_MODULE.SetAudio("BOSS", "rbxassetid://6560398360", 2, 1.2)

		task.wait(1)

		SOUND_MODULE.ChangeVolume("BOSS", 0.5, 5)

		for i, wheel in endingCart.Wheels:GetChildren() do
			task.spawn(function()
				for i = 1, 1000 do
					wheel.Orientation = Vector3.new(i % 360 * -1, 90, 0)
					task.wait()
				end
			end)
		end

		TweenService:Create(endingCart.PrimaryPart, cartTweenInfo, {CFrame = endingCart.PrimaryPart.CFrame * CFrame.new(0, 0, -10)}):Play()

		task.wait(1)

		CHESTER:PivotTo(workspace.ChesterSpawns.ChesterEndingPosition.CFrame * CFrame.new(0, 2, 0))
		local weld = Instance.new("WeldConstraint")
		weld.Parent = CHESTER
		weld.Part0 = CHESTER.PrimaryPart
		weld.Part1 = endingCart.MainCartBody

		task.wait(1.5)

		camera.CFrame = END_CAMS.EndCam.CFrame
		TweenService:Create(camera, TweenInfo.new(15), {CFrame = END_CAMS.FinalEndCam.CFrame}):Play()
		TweenService:Create(endingCart.PrimaryPart, TweenInfo.new(30), {CFrame = workspace.EndingCartTarget.CFrame}):Play()
		TweenService:Create(Lighting, TweenInfo.new(5), {ExposureCompensation = 1}):Play()
		waveTrack:Play()

		local endingScreen = playerGUI.EndingScreen.Frame
		endingScreen.Visible = true

		task.wait(4)

		TweenService:Create(endingScreen.Candles, TweenInfo.new(6, Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
		
		task.wait(10)
		endingScreen.Return.Visible = true
		endingScreen.Return.LobbyButton.Activated:Connect(function()
			DeathScreenRemote:FireServer("LOBBY")
		end)
	end
end)

RESET_CUTSCENE.OnClientEvent:Connect(function()
	if camera.CameraType ~= Enum.CameraType.Custom then
		restoreCamera()
	end
end)