State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------
theStateMachine = State:create{
	initial = "lift",
	substates = {
		-------------------------------
		lift = State:create{
			enterMethod = function() robotIF.setLiftPosition(0.07) print("lift") return 1 end,
			transMethod = function(fdata,data,para)
				print(robotIF.getLiftState())
				if robotIF.getLiftState() == "inactive" then
					return "forward"
					--return "turnLeft"
				end
			end,
		},

		-------------------------------
		forward = State:create{
			enterMethod = function() robotIF.forward() print("forward") end,
			transMethod = function(fdata,data,para)
				if robotIF.objFront() then
					return "backup"
					--return "turnLeft"
				end
			end,
		},
		-------------------------------
		backup = QState:create{
			target = 0.03, speed = robotIF.speedForward,
			enterFunc = robotIF.backup,
			exit = "turnLeft",
		},
		-------------------------------
		turnLeft = QState:create{
			target = 90, speed = robotIF.speedTurn,
			enterFunc = robotIF.turnLeft,
			exit = "along",
		},
		--[[
		turnLeft = State:create{
			enterMethod = function() robotIF.turnLeft()  print("turnLeft") end,
			transMethod = function()
				--if robotIF.objFront() == false and robotIF.getObj(8) == false then
				if robotIF.objFront() == false then
					return "along"
				end
			end,
		},
		--]]
		-------------------------------
		along = State:create{
			transMethod = function()
				if robotIF.nothingAroung() then
					return "forward"
				elseif robotIF.objFront() then
					return "backup"
				end
			end,
			initial = "front",
			substates = {
				----------------------------
				front = State:create{
					enterMethod = function() robotIF.forward(20) print("front") end,
					transMethod = function()
						print("front")
						if robotIF.nearRight() then
							return "frontLeft"
						elseif robotIF.farRight() then
							return "frontRight"
						end
					end,
				},
				----------------------------
				frontLeft = State:create{
					enterMethod = function() robotIF.setVelocity(10,20) print("frontLeft") end,
					transMethod = function()
						print("frontLeft")
						if robotIF.nearRight() == false then
							return "front"
						end
					end,
				},
				----------------------------
				frontRight = State:create{
					enterMethod = function() robotIF.setVelocity(20,10) print("frontRight") end,
					transMethod = function()
						print("frontRight")
						if robotIF.farRight() == false then
							return "front"
						end
					end,
				},
				----------------------------
			}, -- end of substates of along
		}, -- end of along
	} -- end of substates
}

----------------------------------------------------------------------
-- argos function
----------------------------------------------------------------------

local ReadingSum = {
	left = 0,
	right = 0,
	underneath = 0,
	front = 0,
}

local stepcount = 0

-- time -------
local timeHolding

function init()
	reset()
	-- time -----------------
	timeHolding = robotIF.getTime()	--in s

	-------------------------
	--robotIF.disableCamera()
end

function step()
	-- time ----------------------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	timeHolding = timeNow

	-- range finder update -------
	--robotIF.RFUpdate()

	-- state machine -------------
	--theStateMachine:step{time = timePeriod}-- time in s
	
	---[[
	for i = 1,12 do
		print(robotIF.getRFReading(i))
	end
	--]]

	print("left", robotIF.getRFReading("left"))
	print("right", robotIF.getRFReading("right"))
	print("underneath", robotIF.getRFReading("underneath"))
	print("front", robotIF.getRFReading("front"))

	--[[
	stepcount = stepcount + 1;
	for i, v in pairs(ReadingSum) do
		ReadingSum[i] = ReadingSum[i] + robotIF.getRFReading(i)
		local average = ReadingSum[i] / stepcount
		print(i, average)
	end
	--]]
end

function reset()
end

function destroy()
	robotIF.stop()
end
