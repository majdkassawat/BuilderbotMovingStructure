State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------

----------------------------------------------------------------------
-- argos function
----------------------------------------------------------------------

-- time -------
local timeHolding

local counter
local light

function init()
	reset()
	--robotIF.disableCamera()

	-- time -------
	timeHolding = robotIF.getTime()	--in s
	counter = 0
	light = 0
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	timeHolding = timeNow

	print("timePeriod = " .. timePeriod)

	counter = counter + 1
	if counter == 5 then
		light = light + 1
		if light == 5 then light = 0 end
		robotIF.setNFC(light)
		counter = 0
	end
end

function reset()
end

function destroy()
	robotIF.stop()
end
