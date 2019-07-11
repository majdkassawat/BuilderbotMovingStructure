State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------
theStateMachine = State:create{
	initial = "liftCali",
	substates = {
		----------------------------------------------
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
					transMethod = function() robotIF.setLiftPosition(0.07) return "waitPos" end,
				},
				waitPos = State:create{
					transMethod = function()
						if robotIF.liftIdle() == true then return "EXIT" end
					end,
				},
			}, -- end of substates of liftCali
			onExit = "fetch",
		}, -- end of liftCali
		----------------------------------------------
		fetch = State:create{
			initial = "moveDown",
			substates = {
				moveDown = State:create{
					transMethod = function()
						robotIF.setLiftPosition(0.00)
						return "waitDown"
					end,
				},
				waitDown = State:create{
					transMethod = function() 
						if robotIF.liftIdle() == true then return "moveUp" end
					end,
				},
				-------------------------------------------------------------------
				moveUp = State:create{
					transMethod = function()
						robotIF.setLiftPosition(0.07)
						return "waitUp"
					end,
				},
				waitUp = State:create{
					transMethod = function() 
						if robotIF.liftIdle() == true then return "EXIT" end
					end,
				},
				-------------------------------------------------------------------
			},
			onExit = "put",
		}, -- end of fetch
		----------------------------------------------
		put = State:create{
			initial = "moveDown",
			substates = {
				moveDown = State:create{
					transMethod = function()
						robotIF.setLiftPosition(0.065)
						robotIF.chargeMagnet()
						return "waitDown"
					end,
				},
				waitDown = State:create{
					transMethod = function() 
						if robotIF.liftIdle() == true and
						   robotIF.magnetCharged() == true then
							return "drop" end
					end,
				},
				-------------------------------------------------------------------
				drop = State:create{
					transMethod = function()
						robotIF.dropMagnet()
						return "waitDrop"
					end,
				},
				waitDrop = QState:create{
					speed = 1, target = 5, exit = "moveUp",
				},
				-------------------------------------------------------------------
				moveUp = State:create{
					transMethod = function()
						robotIF.setLiftPosition(0.07)
						robotIF.pullMagnet()
						return "waitUp"
					end,
				},
				waitUp = State:create{
					transMethod = function() 
						if robotIF.liftIdle() == true then return "EXIT" end
					end,
				},
				-------------------------------------------------------------------
			},
			onExit = "EXIT",
		}, -- end of fetch
	}, -- end of substates of theStateMachine
} -- end of state machine
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

	print("voltage", robotIF.getMagnetVoltage())
	-- statemachine
	theStateMachine:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.stop()
end
