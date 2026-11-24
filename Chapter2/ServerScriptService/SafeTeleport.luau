local TeleportService = game:GetService("TeleportService")

local ATTEMPT_LIMIT = 5
local RETRY_DELAY = 1
local FLOOD_DELAY = 15

local function SafeTeleport(placeID, players, options)
	local attemptIndex = 0
	local success, result -- define pcall results outside of loop so results can be reported later on
	
	repeat 
		success, result = pcall(function()
			return TeleportService:TeleportAsync(placeID, players, options)
		end)
		attemptIndex += 1
		if not success  then
			task.wait(RETRY_DELAY)
		end		
		
	until success or attemptIndex == attemptIndex
	
	if not success then
		warn(result)
	end
	
	return success, result
end

local function HandleFailedTeleport(player, teleportResult, errorMessage, targetPlaceID, teleportOptions)
	if teleportResult == Enum.TeleportResult.Flooded then
		task.wait(FLOOD_DELAY)
	elseif teleportResult == Enum.TeleportResult.Failure then
		task.wait(RETRY_DELAY)
		
	else
		-- if the teleport is invalid, report the error instead of retrying
		error(("Invalid teleport [%s]: %s"):format(teleportResult.Name, errorMessage))
	end
	
	SafeTeleport(targetPlaceID, {player}, teleportOptions)
end

TeleportService.TeleportInitFailed:Connect(HandleFailedTeleport)

return SafeTeleport