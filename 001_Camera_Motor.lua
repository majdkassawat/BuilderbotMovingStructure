State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------

theStateMachine = State:create{
	data = {
		turnConfig = {
			speed = robotIF.speedTurn,
			enterFunc = robotIF.turn,
			exit = "count",
		},
	},
	initial = "forward",
	substates = {
		forward = State:create{
			enterMethod = function() print("forward") robotIF.forward(15) end,
			transMethod = function(fdata,data,para)
				local Tags, Boxes
				Tags, Boxes = robotIF.getBoxes()
				print("n = ",Boxes.n)
				for i = 1, Boxes.n do
					local loc = robotIF.convertCoorCamRobot(Boxes[i].translation)
					loc.z = 0
					if loc:len() < 0.21 then
						robotIF.stop()

						-- calc degree --
						local robotToBoxL, robotToBoxD
						robotToBoxL, robotToBoxD =
							robotIF.convertCoorCamBox(Boxes[i].cubeDir, Boxes[i].translation)
						robotToBoxD = Vec3:create(robotToBoxD.x, robotToBoxD.y, 0)
							-- dirAng is the ang between robotD and Box's X axis
						local dirAng = math.atan(robotToBoxD.y / robotToBoxD.x) * 180 / math.pi

						if dirAng > 0 then
							fdata.turnConfig.target = 90 - dirAng
								print("------------------------")
								print("target = ",fdata.turnConfig.target)
								print("------------------------")
							fdata.turnConfig.enterPara = 1
						else
							fdata.turnConfig.target = dirAng + 90
							fdata.turnConfig.enterPara = -1
						end

						return "turn"
					end
				end
			end,
		},
		--------------------------------------
		turn = QState:create{
			fdataInit = "turnConfig",
		},
		--------------------------------------
		count = State:create{
			data = {count = 3,},
			enterMethod = function(fdata,data,para) 
				robotIF.forward(15) 
				data.count = 3 
			end,
			transMethod = function(fdata,data,para)
				local Tags, Boxes
				Tags, Boxes = robotIF.getBoxes()

				data.count = data.count - 1
				if (data.count == 0) then return "forward" end
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
	robotIF.enableCamera()

	-- time -------
	timeHolding = robotIF.getTime()	--in s

	robotIF.forward(15)
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	timeHolding = timeNow

	-- statemachine --
	theStateMachine:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.stop()
end
