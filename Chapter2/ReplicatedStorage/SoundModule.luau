local SoundModule = {}

local TweenService = game:GetService("TweenService")
local SOUND = workspace.SOUND

-- key must be one of MUSIC, ACTION, AMBIENCE, BOSS
-- TRANSITION WILL YIELD THREAD IT IS CALLED FROM
function SoundModule.SetAudio(key, id, volume, looped, transition, playbackSpeed, timePos)
	local sound : Sound = SOUND:FindFirstChild(key)
	if transition then
		TweenService:Create(sound, TweenInfo.new(transition), {Volume = 0}):Play()
		task.wait(transition)
	end

	sound.SoundId = id
	sound.Volume = volume or 0.5
	sound.Looped = looped or false
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.TimePosition = timePos or 0
	sound:Play()
	
	if transition then TweenService:Create(sound, TweenInfo.new(transition), {Volume = volume or 0.5}):Play() end
end

function SoundModule.ActionSound(id, volume, speed)
	local actionSound = Instance.new("Sound")
	actionSound.SoundId = id
	actionSound.Volume = volume or 0.5
	actionSound.PlaybackSpeed = speed or 1
	actionSound.Parent = SOUND

	while not actionSound.IsLoaded do task.wait() end
	actionSound:Play()
	actionSound.Ended:Connect(function()
		actionSound:Destroy()
	end)
end

function SoundModule.ChangeVolume(key, volume, transition)
	local sound : Sound = SOUND:FindFirstChild(key)
	TweenService:Create(sound, TweenInfo.new(transition), {Volume = volume}):Play()
end

function SoundModule.Stop(key)
	if not key then 
		for i, sound in SOUND:GetChildren() do sound:Stop() end
	return end
	SOUND:FindFirstChild(key):Stop()
end

return SoundModule
