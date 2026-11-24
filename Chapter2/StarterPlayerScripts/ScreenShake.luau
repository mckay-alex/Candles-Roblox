local ScreenShake = {}

function ScreenShake.Shake(character, duration, value)
	if not character or not duration then return end
	
	task.spawn(function()
		local startTime = time()
		
		repeat task.wait()

		local endTime = time() 

			local XOffSet = math.random(-value, value) / math.random(450, 550)
			local YOffSet = math.random(-value, value) / math.random(450, 550)
			local ZOffSet =math.random(-value, value) / math.random(450, 550)

		character:FindFirstChild("Humanoid").CameraOffset = Vector3.new(XOffSet, YOffSet, ZOffSet)

		until (endTime - startTime) >= duration
		character:FindFirstChild("Humanoid").CameraOffset = Vector3.new(0,0,0)
	end)
end


return ScreenShake
