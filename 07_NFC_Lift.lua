State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------

local theStateMachine = State:create
{
	id = "RobotController",
	initial = "liftCali",
	substates = {
	---------------------------------------------------
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
			},
			onExit = "fetch",
		},
	---------------------------------------------------
		fetch = State:create{
			enterMethod = function()
				print("i am fetch")
				--robotIF.chargeMagnet()
			end,
			leaveMethod = function(fdata,data,para)
				print("i am leaveMethod")
			end,
			initial = "moveDown",
			substates = {
				moveDown = State:create{
					transMethod = function() robotIF.setLiftPosition(0.00) return "waitDown" end,
				},
				waitDown = State:create{
					transMethod = function()
						if robotIF.liftIdle() == true then return "pullMag" end
					end,
				},
				pullMag = State:create{
					transMethod = function()
						robotIF.setNFC("blue")
						print("i am set")
						return "moveUp"
						--[[
						print("waiting charge")
						if robotIF.magnetCharged() == true then
							print("charged, pull")
							robotIF.setNFC("blue")
							robotIF.pullMagnet()
							return "moveUp"
						end
						robotIF.setNFC("blue")
						return "moveUp"	-- dont wait
						--]]
					end,
				},
				moveUp = State:create{
					transMethod = function() robotIF.setLiftPosition(0.07) return "waitPos" end,
					--transMethod = function() robotIF.setLiftPosition(0.07) return "EXIT" end,
				},
				waitPos = State:create{
					transMethod = function()
						print("i am wait in waitPos")
						if robotIF.liftIdle() == true then print("Exit") return "EXIT" end
					end,
				},
			},	-- end of substates of fetch
			onExit = "EXIT",
		},	-- end of fetch
	}, -- end of substates
}  -- end of stateMachine

anotherState = StateMachine:create{
	initial = "count1",
	data = {color = 1,},
	substates = {
		count1 = StateMachine:create{
			data = {
				count = 0,
			},
			enterMethod = function(fdata,data,para)
				data.count = 0
			end,
			transMethod = function(fdata,data,para)
				print(data.count)
				data.count = data.count + 1
				if data.count == 10 then
					return "operate"
				end
			end,
		},
		operate = StateMachine:create{
			transMethod = function(fdata,data,para)
				print("i am operate " .. fdata.color)
				robotIF.setNFC(fdata.color)
				fdata.color = fdata.color + 1
				if fdata.color == 5 then fdata.color = 0 end
				return "count1"
			end,
		},
	},	-- end of substates
}
----------------------------------------------------------------------
-- argos function
----------------------------------------------------------------------

-- time -------
local timeHolding

function init()
	reset()
	robotIF.disableCamera()

	-- time -------
	timeHolding = robotIF.getTime()	--in s
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	timeHolding = timeNow

	print("timePeriod = " .. timePeriod)

	-- statemachine
	--theStateMachine:step{time = timePeriod}
	anotherState:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.stop()
end
