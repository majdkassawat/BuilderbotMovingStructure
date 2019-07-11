-----------------------------------------------------------
--	ZHU Weixu
--		version
-----------------------------------------------------------

local StateMachine = require("StateMachine")
require("blocktracking/func")
local Matrix = require("Matrix")
local Vector = require("Vector")
local Vec3 = require("Vector3")

local individualData = require("individualData")

-----------------------------------------------------------
local robotIF = {}

--------------------------------------------------------------------------------------------
-- Get Time
--------------------------------------------------------------------------------------------
robotIF.getTime = function()
	--return robot.camera_system.get_time()/1000	-- in s
	--return robot.clock.time / 1000	-- in s
	return robot.system.time -- in s
end

robotIF.getTemperature = function()
	return robot.system.temperature -- in s
end

--------------------------------------------------------------------------------------------
-- RangeFinder
--------------------------------------------------------------------------------------------
-- a wave filter --------------
local WaveFilter = {CLASSWAVEFILTER}
WaveFilter.__index = WaveFilter

function WaveFilter:create()
	local instance = {}
	setmetatable(instance,self)

	local recordLength = 8
	instance.record = {}
	instance.i= 1
	instance.recordLength = recordLength

	for i = 1, recordLength do
		instance.record[i] = 0
	end

	return instance
end

function WaveFilter:addData(value)
	self.record[self.i] = value
	if self.i == self.recordLength then self.i = 1
								   else self.i = self.i + 1 end
end

function WaveFilter:getData()
	local order = {}
	for i = 1, self.recordLength do
		order[i] = 1
	end
	for i = 1, self.recordLength do
		for j = 1, i-1 do
			if self.record[i] >= self.record[j] then
				order[i] = order[i] + 1
			else
				order[j] = order[j] + 1
			end
		end
	end
	for i = 1, self.recordLength do
		if order[i] == self.recordLength / 2 then
			return self.record[i]
		end
	end
end

--- range finder ----------------------------

function robotIF.getRFReading(number)
	if type(number) == "number" then
		return robot.rangefinders[tostring(number)].proximity
	else
		return robot.rangefinders[number].proximity
	end
end

robotIF.RangeFinder = {}
for i = 1, 12 do
	robotIF.RangeFinder[i] = WaveFilter:create()
end

robotIF.RangeFinder.index = individualData.RangeFinderIndex

function robotIF.RFUpdate()
	for i = 1, 12 do
		robotIF.RangeFinder[i]:addData(robotIF.getRFReading(i))
	end
end

function robotIF.getRFFiltedReading(number)
	return robotIF.RangeFinder[number]:getData()
end

function robotIF.getDis(number)
	local reading = robotIF.getRFFiltedReading(number)
	local index = robotIF.RangeFinder.index[number]
	local disNum = -1

	for i = 1, robotIF.RangeFinder.index.resolution do
		if reading > index[i] then
			disNum = i - 1
			break
		end
	end
	if disNum == -1 then
		disNum = robotIF.RangeFinder.index.resolution
	end
	-- disNum now is the index in the Matrix
	return (disNum-1) * robotIF.RangeFinder.index.lengthPerRes	-- count from 0, in mm
end

function robotIF.getObj(number)
	if robotIF.getDis(number) <= 45 then
		return true else return false end
end

function robotIF.objFront()
	if robotIF.getDis(6) <= 40 or robotIF.getDis(7) <= 40 then
		return true else return false end
end

function robotIF.farRight()
	--if robotIF.getDis(9) >= 35 or robotIF.getDis(10) >= 35 then
	if robotIF.getDis(9) >= 35 and robotIF.getDis(8) >= 35 then
		return true else return false end
end

function robotIF.nearRight()
	--if robotIF.getDis(9) <= 20 or robotIF.getDis(10) <= 20 then
	if robotIF.getDis(9) <= 30 and robotIF.getDis(8) <= 30 then
		return true else return false end
end

function robotIF.nothingAroung()
	local flag = 0
	for i = 1,12 do
		if robotIF.getObj(i) == true then 
			flag = 1
			return false
		end
	end
	if flag == 0 then return true end
end

--------------------------------------------------------------------------------------------
-- Speed control
--------------------------------------------------------------------------------------------
robotIF.setVelocity = function(x,y)
	robot.differential_drive.set_target_velocity(x, y)
end

----- forward --------
--10 : 30cm/23s
--15 : 30cm/16s
--20 : 30cm/11s
--30 : 30cm/8s
robotIF.speedForward = 0.3/16	-- m/s	for 15
--robotIF.speedForward = 0.3/11	-- m/s	for 20
--robotIF.speedForward = 0.3/8	-- m/s	for 30
local defForward = 0.3/16  --m/s
robotIF.forward = function(x)
	--robotIF.setVelocity(20,20)
	if x == nil then
		robotIF.setVelocity(defForward,-defForward)
	else
		robotIF.setVelocity(x,x)
	end
end

robotIF.backup = function(x)
	--robotIF.setVelocity(20,20)
	if x == nil then
		robotIF.setVelocity(-defForward,defForward)
	else
		robotIF.setVelocity(x,x)
	end
end

----- turn --------
--(30 -30) : 360deg/10s
--(20 -20) : 360deg/16s
--(15 -15) : 360deg/20s
--(10 -10) : 360deg/33s
--robotIF.speedTurn = 36	-- deg/s for 30 -30
robotIF.speedTurn = 360 / 16	-- deg/s for 10 -15
--robotIF.speedTurn = 360 / 20	-- deg/s for 10 -15
--robotIF.speedTurn = 360 / 33	-- deg/s for 10 -10
local def = 0.3/11 -- m/s
robotIF.turnLeft = function(x)
	if x == nil then
		robotIF.setVelocity(-def,-def)
	else
		if x > 1 then print("too much") x = 0.05 end
		robotIF.setVelocity(-x,-x)
	end
end
robotIF.turnRight = function(x)
	if x == nil then
		robotIF.setVelocity(def,def)
	else
		if x > 1 then print("too much") x = 0.05 end
		robotIF.setVelocity(x,x)
	end
end
robotIF.turn = function(x)	-- >0 left <0 right
	if x > 0 	then robotIF.turnLeft()
				else robotIF.turnRight() 	end
end

----- stop --------
robotIF.stop = function()
	robotIF.setVelocity(0,0)
end

--------------------------------------------------------------------------------------------
-- Lift control
--------------------------------------------------------------------------------------------
robotIF.getLiftState = function()
	return robot.lift_system.state
end

robotIF.getLiftPosition = function()
	return robot.lift_system.position		-- in m
end

robotIF.getSwitches = function()			-- bottom 1, top 2, nothing 0
	if robot.lift_system.limit_switches.top == 1 then
		return 2 end
	if robot.lift_system.limit_switches.bottom == 1 then
		return 1 end
	return 0
end

robotIF.liftCalibrate = function()
	robot.lift_system.calibrate()
end

robotIF.setLiftPosition = function(number)
	robot.lift_system.set_position(number)		-- in m
end

robotIF.liftIdle = function()
	if robotIF.getLiftState() == "inactive" then
		return true else return false end
end

--------------------------------------------------------------------------------------------
-- NFC control nfc
--------------------------------------------------------------------------------------------
robotIF.setNFC = function(x)
	if x == "pink" or x == 1 then
		robot.nfc.write("1")
	elseif x == "orange" or x == 2 then
		robot.nfc.write("2")
	elseif x == "green" or x == 3 then
		robot.nfc.write("3")
	elseif x == "blue" or x == 4 then
		robot.nfc.write("4")
	else
		robot.nfc.write("0")
	end

		--os.execute("echo 1 > /dev/nfc")	-- use this in case argos nfc doesn't work
end

--------------------------------------------------------------------------------------------
-- Magnet control
--------------------------------------------------------------------------------------------
robotIF.chargeMagnet = function()
	robot.electromagnet_system.set_discharge_mode("disabled")
end

robotIF.getMagnetVoltage = function()
	return robot.electromagnet_system.voltage
end

robotIF.magnetCharged = function()
	if robotIF.getMagnetVoltage() > 22 then
		return true else return false end
end

robotIF.dropMagnet = function()
	robot.electromagnet_system.set_discharge_mode("destructive")
end

robotIF.pullMagnet = function()
	robot.electromagnet_system.set_discharge_mode("constructive")
end

--------------------------------------------------------------------------------------------
-- Camera control
--------------------------------------------------------------------------------------------
robotIF.enableCamera = function()
	robot.camera_system.enable()
end
robotIF.disableCamera = function()
	robot.camera_system.disable()
end
robotIF.getBoxes = function()
	robot.camera_system.tags.n = #robot.camera_system.tags
	local Tags, Boxes = blocktracking(robot.camera_system.tags)
				-- if DEBUG == true then print("I see", Boxes.n, "boxes") end
	return Tags, Boxes
end

robotIF.chooseBoxes= function(_Boxes)
	if _Boxes.n == 0 then return nil end
	local index
	local dis = 1.0	-- unit m
	for i = 1, _Boxes.n do
		local boxToRobot = robotIF.convertCoorCamRobot(_Boxes[i].translation)
		boxToRobot.z = 0
		boxToRobot.y = boxToRobot.y - 0.05
		if boxToRobot:len() < dis then
			dis = boxToRobot:len()
			index = i
		end
	end
	return _Boxes[index]
end

robotIF.boxInsight = function()
	if #robot.camera_system.tags ~= 0 	then return true
										else return false end
end
----Open/Close CameraState------------------------------------------------
robotIF.EnableCameraState = {CLASSENABLECAMERASTATE = true}
robotIF.EnableCameraState.__index = robotIF.EnableCameraState
setmetatable(robotIF.EnableCameraState,StateMachine)

function robotIF.EnableCameraState:new(option)
	return self:create(option)
end
function robotIF.EnableCameraState:create(option)
	local instance = StateMachine:create{
		id = option.id,
		data = {
			_exit = option.exit,
			_fdataInit = option.fdataInit
		},
		enterMethod = function(fdata,data,para)
			if data._fdataInit == true then
				data._exit = fdata.EnableCameraStateOption.exit
			end

			robotIF.enableCamera()
		end,
		transMethod = function(fdata,data,para)
			return data._exit
		end,
	}
	return instance
end

robotIF.DisableCameraState = {CLASSDISABLECAMERASTATE = true}
robotIF.DisableCameraState.__index = robotIF.DisableCameraState
setmetatable(robotIF.DisableCameraState,StateMachine)

function robotIF.DisableCameraState:new(option)
	return self:create(option)
end
function robotIF.DisableCameraState:create(option)
	local instance = StateMachine:create{
		id = option.id,
		data = {
			_exit = option.exit,
			_fdataInit = option.fdataInit,
			count = 0,
		},
		enterMethod = function(fdata,data,para)
			if data._fdataInit ~= nil then
				data._exit = fdata[data._fdataInit].exit
			end

			data.count = 0
			robotIF.disableCamera()
		end,
		transMethod = function(fdata,data,para)
			data.count = data.count + 1
			--if data.count == 2 then	-- wait one more frame to make the time measure normal
			if data.count == 1 then	-- quit immediately
				return data._exit
			end
		end,
	}
	return instance
end

----wait and see State------------------------------------------------
robotIF.WaitAndSeeState = {CLASSWAITANDSEESTATE = true}
robotIF.WaitAndSeeState.__index = robotIF.WaitAndSeeState
setmetatable(robotIF.WaitAndSeeState,StateMachine)

function robotIF.WaitAndSeeState:create(option)
	local instance = StateMachine:create{
		id = option.id,
		data = {
			box = nil,
			DisableCameraStateOption = {exit = nil,},
		},
		enterMethod = function(fdata,data,para)
			data.box = nil
		end,
		leaveMethod = function(fdata,data,para)
			fdata.box = data.box
		end,
		onExit = option.exit,
		initial = "openCamera",
		substates = {
			openCamera = robotIF.EnableCameraState:create{
				exit = "waitAndSee",
			},
			closeCamera = robotIF.DisableCameraState:create{
				exit = "EXIT",
			},
			waitAndSee = State:create{
				data = {
					stillCount = 0,
					lostCount = 0,
				},
				enterMethod = function(fdata, data, para)
					data.stillCount = 0
					data.lostCount = 0
				end,
				transMethod = function(fdata, data, para)	-- count, if steady, approach
					local Tags, Boxes = robotIF.getBoxes()
					-- nothing interesting close camera and keep looking
					if robotIF.boxInsight() == false and data.stillCount == 0 then 
						fdata.box = nil
						return "closeCamera"
					end
			
					-- I have seen one box but I lost it, start count
					if robotIF.boxInsight() == false then
						data.lostCount = data.lostCount + 1
						-- waited long enough, forget it and keep finding
						if data.lostCount > 2 then 
							fdata.box = nil
							return "closeCamera"
						-- keep waiting for the next step
						else
							return nil
						end
					-- I see one box!
					else
						data.lostCount = 0
						-- This is the first time I see it, record and next round
						if data.stillCount == 0 then 
							fdata.box = tableCopy(Boxes[1]) 
							data.stillCount = data.stillCount + 1
							--return nil 	-- wait for seeing it for the second time
							return "closeCamera"	-- close immediately
						-- This is not the first time I see it
						else
							local length = (fdata.box.translation - Boxes[1].translation):len()
							-- I see this box twice, clear and steady
							if length < 0.001 then
								data.stillCount = data.stillCount + 1
							-- it not steady
							else
								data.stillCount = 0
							end
			
							-- not steady yet
							if data.stillCount < 2 then return nil end
			
							-- steady!
							return "closeCamera"
						end
					end
				end,
			}, -- end of waitAndSee
		},
	} -- end of instance
	return instance
end

---- Coordination Convert----------------------------------------------
-- Camera Sight
-- Left x-, Right x+
-- Up   y-, Down  y+
-- Near z-, Far   z+
local function findBoxCoor(cubeDir)
	-- find xyz
	-- z is the one pointing up
	-- x is the one pointing towards me
	local x = {}
	local y = {}
	local z = {}
	local ix = 0
	local iy = 0
	local iz = 0
	for i = 1,6 do
		if cubeDir[i].y < 0 and cubeDir[i].z <= 0 then
			iz = iz + 1
			z[iz] = cubeDir[i]
		end
		if cubeDir[i].y > 0 and cubeDir[i].z < 0 then
			ix = ix + 1
			x[ix] = cubeDir[i]
		end
	end
	if iz == 1 then 
		z = z[1]
	elseif iz == 2 then
		if z[1].x < z[2].x then z = z[1]
						   else z = z[2] end
	else
		print("impossible box! iz == 3") return nil
	end

	if ix == 1 then
		x = x[1]
	elseif ix == 2 then
		if x[1].z < x[2].z 	then x = x[1]
							else x = x[2]
		end
	else
		print("impossible box! ix == 3") return nil
	end

	y = z * x

	return x,y,z
end
function robotIF.convertCoorCamBox(cubeDir, location)	
-- compute the location of Camera in Box's coordinate system
-- TODO: make it location of the robot

	-- cubeDir is the direction of cube, location is the location of the cube, in Camera's eye
	-- return CamL, camD the location and direction of the camera to the box
	-- the coordination system of the cube, x axis points to the camera
	local xBox,yBox,zBox
	xBox, yBox, zBox = findBoxCoor(cubeDir)
	local aMat = Matrix:create({
		{xBox.x, yBox.x, zBox.x},
		{xBox.y, yBox.y, zBox.y},
		{xBox.z, yBox.z, zBox.z},
	})
	local r_aMat = aMat:reverse()

	local v_loc = -Vector:create({location.x, location.y, location.z})
	local coorCam_vec = r_aMat * v_loc
	local coorCam_vec3 = Vec3:create(	coorCam_vec[1],
										coorCam_vec[2],
										coorCam_vec[3])

	local v_loc = Vector:create({0, 0, 1})
	local coorCamDir_vec = r_aMat * v_loc
	local coorCamDir_vec3 = Vec3:create(coorCamDir_vec[1],
										coorCamDir_vec[2],
										coorCamDir_vec[3])

	return coorCam_vec3, coorCamDir_vec3
end
function robotIF.convertCoorCamRobot(loc)	
-- compute the location of Box in Robot's coordinate system
	-- robot Axis : x right y front z up
	-- camera Axis : x right y down z far
	local xCamD, yCamD, zCamD, xCamL, yCamL, zCamL
		-- axis of camera in robot coordination	system
	xCamD = (Vec3:create( 1, 0, 0)):nor()
	yCamD = (Vec3:create( 0,-1,-1)):nor()
	zCamD = (Vec3:create( 0, 1,-1)):nor()
	--CamL = Vec3:create( 0, 0.10, 0.20)		-- calc from the location of the manip
	CamL = Vec3:create( 0, 0.13, 0.20)		-- calc from the location of the manip
	local aMat = Matrix:create{
		{xCamD.x, yCamD.x, zCamD.x},
		{xCamD.y, yCamD.y, zCamD.y},
		{xCamD.z, yCamD.z, zCamD.z},
	}

	local v_loc = Vector:create({loc.x, loc.y, loc.z})	-- calc from the location of the manip
	local locVec = aMat * v_loc
	local locVec3 = Vec3:create(locVec[1],locVec[2],locVec[3])
	locVec3 = locVec3 + CamL

	return locVec3
end

return robotIF
