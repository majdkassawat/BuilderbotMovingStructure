State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------
		liftCali = State:create{
			initial = "startCali",
			substates = {
				startCali = State:create{
					transMethod = function() robotIF.liftCalibrate() return "waitCali" end,
				},
				waitCali = State:create{
					transMethod = function()
						if robotIF.liftIdle() == true then return "moveMiddle" end
					end,
				},
				moveMiddle = State:create{
					transMethod = function() robotIF.setLiftPosition(0.05) return "waitPos" end,
				},
				waitPos = State:create{
					transMethod = function()
						if robotIF.liftIdle() == true then return "EXIT" end
					end,
				},
			},
		}
----------------------------------------------------------------------
-- argos function
----------------------------------------------------------------------

-- time -------
local timeHolding

function init()
	reset()
	--robotIF.disableCamera()

	-- time -------
	timeHolding = robotIF.getTime()	--in s
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	timeHolding = timeNow

	print("state = ", robotIF.getLiftState())
	print("position = ", robotIF.getLiftPosition())

	-- statemachine
	liftCali:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.stop()
end
