local State = require("StateMachine")
local QState = require("QuantityState")
local robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------
theStateMachine = State:create{
	initial = "forward",
	substates = {
		-------------------------------
		forward = QState:create{
			target = 0.2,
			speed = robotIF.speedForward,
			enterFunc = robotIF.forward,
			exit = "turnLeft",
		},
		-------------------------------
		turnLeft = QState:create{
			target = 90,
			speed = robotIF.speedTurn,
			enterFunc = robotIF.turnLeft,
			exit = "forward",
		},
		-------------------------------
	} -- end of substates
}

----------------------------------------------------------------------
-- argos function
----------------------------------------------------------------------

-- time -------
local timeHolding

function init()
	reset()


	-- time -------
	timeHolding = robotIF.getTime()	--in s
	
	--robotIF.turnLeft()
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	print("timePeriod", timePeriod)

	print("gettime", robotIF.getTime())
	timeHolding = timeNow

	theStateMachine:step{time = timePeriod}-- time in s
	print("left:  " .. robot.differential_drive.encoders.left)
	print("right: " .. robot.differential_drive.encoders.right)
end

function reset()
end

function destroy()
	robotIF.stop()
end
