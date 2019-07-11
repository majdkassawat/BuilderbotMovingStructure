
State = require("StateMachine")
QState = require("QuantityState")
robotIF = require("RobotInterface")

Vec3 = require("blocktracking/math/Vector3")
Quaternion = require("blocktracking/math/Quaternion")
local debug = 1

----------------------------------------------------------------------
-- stateMachine
----------------------------------------------------------------------

----------------------------------------------------------------------
-- argos function
----------------------------------------------------------------------

-- time -------
local timeHolding
local camerastate

function init()
	reset()
	robotIF.enableCamera()
	camerastate = true

	-- time -------
	timeHolding = robotIF.getTime()	--in s
end

function step()
	-- time -------
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding
	timeHolding = timeNow

	print("temperature", robotIF.getTemperature())
	print("time", timePeriod)
	if camerastate == true then
		if robotIF.getTemperature() > 115 then
			robotIF.disableCamera()
			camerastate = false
		end
	else
		if robotIF.getTemperature() < 104 then
			robotIF.enableCamera()
			camerastate = true 
		end
	end

	--[[
	local detectled = robot.camera_system.detect_led(319,0,10,10)

	print("detectled return :", detectled)
	--]]
   

	-- block tracking --
	local Tags, Boxes
	Tags, Boxes = robotIF.getBoxes()

   print("argos result ---------")
   for i, v in ipairs(robot.camera_system.tags) do
      print("position = ", Vec3:create(v.position.x,v.position.y,v.position.z))
      local q = Quaternion:createFromRotation(
         v.orientation.axis.x,
         v.orientation.axis.y,
         v.orientation.axis.z,
         v.orientation.angle
      )
      print("quaternion = ", q)
      print("rotation= ", q:toRotate(Vec3:create(0,0,-1)))
   end

   print("lua result ---------")
	print("n = ",Boxes.n)
	for i = 1, Tags.n do
		print("position = ", Tags[i].translation)
		print("quaternion = ", Tags[i].quaternion)
		print("rotation = ", Tags[i].rotation)
	end
   ---[[
	print("n = ",Boxes.n)
	for i = 1, Boxes.n do
		print(Boxes[i].translation)
	end
   --]]
end

function reset()
end

function destroy()
	robotIF.stop()
end
