--[[
--	for Michael's manipulator
--]]
DEBUG = true

State = require("StateMachine")
QuantityState = require("QuantityState")
robotIF = require("RobotInterface")
Vec3 = require("Vector3")

pprint = require('pprint')






local timeHolding
local stepCount
function init()
	reset()
	timeHolding = robotIF.getTime()	-- in s
	stepCount = 0
	robotIF.enableCamera()
	-- robotIF.setLiftPosition(0.05)

	
end

function step()
	stepCount = stepCount + 1
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding	-- unit s
	timeHolding = timeNow


	local Tags,Boxes = robotIF.getBoxes()
	if robotIF.boxInsight() == true then
		for i=1,Boxes[1].nTags do --check if there is any tag detected
			print(Boxes[1][i].label,Boxes[1][i].rotation)
		end
	end
	--Here we should have a mixer
	
	print("------- count",stepCount,"time",timePeriod,"------------")
	-- theStateMachine:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.setVelocity(0,0)
end
