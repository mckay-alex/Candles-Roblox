local StarterGui = game:GetService("StarterGui")

repeat
	local success, errorMsg = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", false)
	end)
	task.wait(1)
until success
	
	


