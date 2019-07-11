State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------
		Fetch = State:create{
			initial = "start",
			substates = {
				start = State:create{
					transMethod = function() 
						print("i am charge again")
						robotIF.chargeMagnet() 
						return "waitCharge" 
					end,
				},
				waitCharge = State:create{
					transMethod = function()
						if robotIF.magnetCharged() == true then return "drop" end
					end,
				},
				drop = State:create{
					transMethod = function() 
						print("i am drop")
						robotIF.dropMagnet() 
						return "waitdrop" 
					end,
				},
				waitdrop = QState:create{
					speed = 1, target = 5, exit = "chargeAgain",
				},
				chargeAgain = State:create{
					transMethod = function() 
					print("i am charge again")
					robotIF.chargeMagnet() return "waitAgain" end,
				},
				waitAgain= State:create{
					transMethod = function()
						if robotIF.magnetCharged() == true then return "pick" end
					end,
				},
				pick = State:create{
					transMethod = function() 
						print("i am pull")
						robotIF.pullMagnet() 
						return "waitpull" 
					end,
				},
				waitpull = QState:create{
					speed = 1, target = 5, exit = "start",
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
   robotIF.setLiftPosition(0.002);
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	timeHolding = timeNow

	-- statemachine
	Fetch:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.stop()
end
