State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
----------------------------------------------------------------------
-- argos function
----------------------------------------------------------------------

-- time -------
local timeHolding

function init()
	reset()

	-- time -------
	timeHolding = robotIF.getTime()	--in s
	
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	print("timePeriod", timePeriod)
	timeHolding = timeNow

	print("temperature = ", robotIF.getTemperature())
end

function reset()
end

function destroy()
end
