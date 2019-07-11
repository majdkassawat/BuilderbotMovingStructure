--[[
--	for Michael's manipulator
--]]
DEBUG = true

State = require("StateMachine")
QuantityState = require("QuantityState")
robotIF = require("RobotInterface")

Vec3 = require("Vector3")






--[[
	-- time  --
	getTime()	in ms
	-- speed --
	setVelocity(x,y)
	speedForward
	forward()
	speedTurn
	turnLeft(), turnRight(), turn(x)	>0 left <0 right
	stop()

	-- manipulator --
	getLiftState()
	getLiftPosition()
	getSwitches()	nothing 0    touching bottom 1   touching top 2
	liftIdle()
	setLiftPosition()
	liftCalibrate()

	-- magnet --
	chargeMagnet()
	getMagnetVoltage()
	magnetCharged()
	dropMagnet()
	pullMagnet()

	-- camera --
	enableCamera(), disableCamera()
	Tags, Boxes = getBoxes()
	boxInsight()
	EnableCameraState, DisableCameraState
--]]

function tableCopy(x)
	local image = {}
	setmetatable(image,getmetatable(x))
	if type(x) ~= "table" then return x end
	for index,value in pairs(x) do
		image[index] = tableCopy(value)
	end
	return image
end

function tableCopyWithoutNeighbour(x)
	local image = {}
	setmetatable(image,getmetatable(x))
	if type(x) ~= "table" then return x end
	for index,value in pairs(x) do
		if index ~= "neighbour" then
			image[index] = tableCopyWithoutNeighbour(value)
		end
	end
	return image
end
---------------------------------------------------------------------------------------
-- State Machine
---------------------------------------------------------------------------------------
	--	camera default disabled
local theStateMachine = State:create
{
	id = "RobotController",
	data = {
		box = nil,	-- the focal box
		holdingState = false, -- whether I am holding a box
	},
	initial = "findingBox",
	--initial = "backup",
	--initial = "findingBox",
	substates = {
	---------------------------------------------------
		liftCali = State:create{
			--initial = "startCali",
			initial = "moveMiddle",
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
			onExit = "findingBox",
		},
	---------------------------------------------------
		findingBox = State:create{
			id = "findingBox",
			data = {
				DisableCameraStateOption = {exit = nil},
				box = nil,
			},

			leaveMethod = function(fdata,data,para)
				fdata.box = data.box
			end,

			---[[
			initial = "openCamera",
			onExit = "EXIT",
			substates = {
				openCamera = robotIF.EnableCameraState:create{
					exit = "turn",
				},
				turn = State:create{
					enterMethod = function()
						robotIF.turnLeft(0.3/23)
					end,
					transMethod = function()
						--local Tags,Boxes = robotIF.getBoxes()
						if robotIF.boxInsight() == true then
							print("i am turn, and before return storeBox")
							return "storeBox"
						end
					end,
					leaveMethod = function()
						robotIF.stop()
					end,
				},
				storeBox = State:create{
					transMethod = function(fdata,data,para)
						print("i am storeBox before getBoxes")
						local Tags,Boxes = robotIF.getBoxes()
						fdata.box = tableCopyWithoutNeighbour(Boxes[1])
						print("before printing box details")
						os.setlocale("en_US.UTF-8")
						-- print(0.2)
						print(fdata.box.cubeDir)
						print("after printing box details")
						print("i am storeBox and closeCamera")

						robotIF.disableCamera()
						return "EXIT"

						--return "closeCamera"
					end,
				},
				closeCamera = robotIF.DisableCameraState:create{
					exit = "EXIT",
				},
			}, -- end of substates of findingBox
			--]]

			--[[
			initial = "waitAndSee",
			onExit = "approach",	-- if the substates of findingBox exit, goto approach
			substates = {
			---------------------------------------------
				turn30 = QuantityState:create{
					target = 30,
					speed = robotIF.speedTurn,
					enterFunc = robotIF.turnLeft,
					leaveFunc = robotIF.stop,
					exit = "waitAndSee",
				},
			---------------------------------------------
				waitAndSee = robotIF.WaitAndSeeState:create{
					exit = "tryBox",
				},
			---------------------------------------------
				tryBox = State:create{
					transMethod = function(fdata,data,para)
						if fdata.box ~= nil then
							return "EXIT"
						else
							return "turn30"
						end
					end
				},
			---------------------------------------------
			}, -- end of substates of findingBox
			--]]
		}, -- end of findingBox
	---------------------------------------------------
		approach = State:create{
			data = {
				turn1QOption = 
					{speed = robotIF.speedTurn, leaveFunc = robotIF.stop, exit = "forward1",},
				forward1QOption = 
					{speed = robotIF.speedForward, leaveFunc = robotIF.stop, exit = "turn2",},
				turn2QOption = 
					--{speed = robotIF.speedTurn, leaveFunc = robotIF.stop, exit = "waitAndSee",},
					{speed = robotIF.speedTurn, leaveFunc = robotIF.stop, exit = "enableCamera",},
				aimingQOption = 
					{speed = robotIF.speedTurn, leaveFunc = robotIF.stop, exit = "waitAndSee",},
				forward2QOption = 
					{speed = robotIF.speedForward, leaveFunc = robotIF.stop, exit = "EXIT",},

				DisableCameraStateOption = {exit = nil},
				box = nil,
				holdingState = false,
			},
			enterMethod = function(fdata,data,para)
				data.holdingState = fdata.holdingState
				local robotToBoxL, robotToBoxD
				robotToBoxL, robotToBoxD = 
					robotIF.convertCoorCamBox(fdata.box.cubeDir, fdata.box.translation)
				robotToBoxL = Vec3:create(robotToBoxL.x, robotToBoxL.y, 0)
				robotToBoxD = Vec3:create(robotToBoxD.x, robotToBoxD.y, 0)
				robotToBoxL = robotToBoxL - robotToBoxD * 0.12 
				-- in the coordination of the box, L is the location, D is the direction of the robot
				-- the face pointing to the robot is x axis of the box coordination
				-- calc first turn
					-- dirAng is the ang between robotD and Box's X axis
				local dirAng = math.atan(robotToBoxD.y / robotToBoxD.x) * 180 / math.pi
						-- robotToBoxD.x must < 0 (if > 0, the robot won't see the box)
						if robotToBoxD.x > 0 then print("impossible happend") return "findingBox" end
						-- so dirAng should be from -90(towards y+) to 90 (towards y-)
						-- but x axis is always the one near robot, so 
						--  	dirAng is actually -45(towards y+) to 45 (towards y-)
						
					-- firstPoint is the place robot should be in the first move
					-- dirTarAng is the ang between X axis and the dir of firstPoint
				local firstPointDis = 0.17
				local dirTarAng
				if firstPointDis == robotToBoxL.x then
					dirTarAng = 90
					if robotToBoxL.y < 0 then dirTarAng = -90 end
				else
					dirTarAng = math.atan(robotToBoxL.y/(robotToBoxL.x-firstPointDis))*180/math.pi
					if firstPointDis > robotToBoxL.x then 
						if robotToBoxL.y > 0 then
							dirTarAng = dirTarAng + 180
						else
							dirTarAng = dirTarAng - 180
						end
					end
				end

					-- firstPoint is the ang the robot should rotate, right- left+
				local firstAng = dirTarAng - dirAng
				local absAng = firstAng
				local dirAng = 1
				if firstAng < 0 then absAng = -absAng; dirAng = -1 end
				data.turn1QOption.target = absAng
				data.turn1QOption.enterFunc = robotIF.turn
				data.turn1QOption.enterPara = dirAng
						print("firstAng",absAng)
						print("firstDir",dirAng)

				-- calc first forward
				local X = robotToBoxL.x - firstPointDis 
				local Y = robotToBoxL.y 
				local Dis = math.sqrt(X * X + Y * Y)
				data.forward1QOption.target = Dis
				data.forward1QOption.enterFunc = robotIF.forward
						print("firstdis",Dis)
				-- calc second turn
				local secondAng = -dirTarAng
				absAng = secondAng
				dirAng = 1
				if secondAng < 0 then absAng = -absAng; dirAng = -1 end
				data.turn2QOption.target = absAng
				data.turn2QOption.enterFunc = robotIF.turn
				data.turn2QOption.enterPara = dirAng
						print("secondAng",absAng)
						print("secondDir",dirAng)
			end,
			onExit = "fetchOrPut",
			initial = "turn1",
			substates = {
				turn1 = QuantityState:create{
					fdataInit = "turn1QOption",
				},
				forward1 = QuantityState:create{
					fdataInit = "forward1QOption",
				},
				turn2 = QuantityState:create{
					fdataInit = "turn2QOption",
				},
				waitAndSee = robotIF.WaitAndSeeState:create{
					exit = "aimCheck",
				},
				----------------------------------------------
				lostTurn = State:create{
					enterMethod = function(fdata,data,para)
						robotIF.enableCamera()
						fdata.turn2QOption.enterFunc(fdata.turn2QOption.enterPara)
							-- keep turning if see nothing
					end,
					transMethod = function(fdata,data,para)
						if robotIF.boxInsight() == true then return "aimcheck" end
					end,
					leaveMethod = function(fdata,data,para)
						robotIF.stop()
						robotIF.disableCamera()
					end,
				},	-- end of lostTurn
				----------------------------------------------
				enableCamera = robotIF.EnableCameraState:create{
					exit = "aimCheck",
				},
				----------------------------------------------
				aimCheck = State:create{
					data = {count = 0,},
					transMethod = function(fdata,data,para)
						print("i am aimcheck")
						local Tags, Boxes = robotIF.getBoxes()
						-- check fdata.box == nil
						if Boxes.n == 0 then return "lostTurn" end

						local theBox = robotIF.chooseBoxes(Boxes)
						-- assume the box is already towards me
						local boxToRobot = robotIF.convertCoorCamRobot(theBox.translation)
							-- y front, x right
						print("boxToRobot",boxToRobot)
						local boxAng = math.atan(-boxToRobot.x / boxToRobot.y) * 180/math.pi
						boxAng = boxAng + 2  -- a compensation for the camera
							-- from -90 to 90, left +
						print("boxAng = ",boxAng)
						local gate = 1
						if boxAng < gate and boxAng > -gate then
							robotIF.stop()
							data.count = data.count + 1
							if data.count < 3 then return end

							local Dis = boxToRobot.y - 0.14
							print("ok!,dis = ",Dis)
							fdata.forward2QOption.target = Dis
							fdata.forward2QOption.enterFunc = robotIF.forward

							if fdata.holdingState == false then
								robotIF.setLiftPosition(0.01)
							end
							robotIF.disableCamera()
							return "forward2"
						else
							print("not ok")
							data.count = 0
							--if boxAng > gate then robotIF.turnLeft(boxAng)
							--elseif boxAng < -gate then robotIF.turnRight(-boxAng) end
							local abs = boxAng
							if abs < 0 then abs = -abs end
							local speed = 5 * 0.0012875494071146
							if abs < 3 then speed = 3 * 0.0012875494071146 end
							if abs < 2 then speed = 2 * 0.0012875494071146 end
							if boxAng > gate then robotIF.turnLeft(speed)
							elseif boxAng < -gate then robotIF.turnRight(speed) end
						end
					end,
				}, -- end of aimCheck
				----------------------------------------------
				aiming = QuantityState:create{
					fdataInit = "aimingQOption",
				},
				forward2 = QuantityState:create{
					fdataInit = "forward2QOption",
				},
			},	-- end of substates of approach
		}, -- end of approach
	---------------------------------------------------
		fetchOrPut = State:create{
			transMethod = function(fdata,data,para)
				if fdata.holdingState == false then
					return "fetch"
				else
					return "put"
				end
			end,
		},
	---------------------------------------------------
		put = State:create{
			enterMethod = function()
				print("i am put")
				robotIF.chargeMagnet()
			end,
			leaveMethod = function(fdata,data,para)
				fdata.holdingState = false
			end,
			--onExit = "findingBox",
			initial = "moveDown",
			substates = {
				moveDown = State:create{
					transMethod = function() robotIF.setLiftPosition(0.055) return "waitDown" end,
				},
				waitDown = State:create{
					transMethod = function()
						if robotIF.liftIdle() == true then return "pullMag" end
					end,
				},
				pullMag = State:create{
					transMethod = function()
						print("waiting charge")
						if robotIF.magnetCharged() == true then
							print("charged, pull")
							robotIF.setNFC("pink")
							robotIF.dropMagnet()
							return "moveUp"
						end
						robotIF.setNFC("pink")
						return "moveUp"	-- dont wait
					end,
				},
				moveUp = State:create{
					--transMethod = function() robotIF.setLiftPosition(0.07) return "waitPos" end,
					transMethod = function() robotIF.setLiftPosition(0.07) return "EXIT" end,
				},
				waitPos = State:create{
					transMethod = function()
						if robotIF.liftIdle() == true then return "EXIT" end
					end,
				},
			},	-- end of substates of put
			onExit = "backup",
		},	-- end of put
	---------------------------------------------------
		fetch = State:create{
			enterMethod = function()
				print("i am fetch")
				robotIF.chargeMagnet()
			end,
			leaveMethod = function(fdata,data,para)
				fdata.holdingState = true
			end,
			onExit = "findingBox",
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
						print("waiting charge")
						if robotIF.magnetCharged() == true then
							print("charged, pull")
							robotIF.pullMagnet()
							robotIF.setNFC("orange")
							return "moveUp"
						end
						robotIF.setNFC("orange")
						return "moveUp"	-- dont wait
					end,
				},
				moveUp = State:create{
					--transMethod = function() robotIF.setLiftPosition(0.07) return "waitPos" end,
					transMethod = function() robotIF.setLiftPosition(0.07) return "EXIT" end,
				},
				waitPos = State:create{
					transMethod = function()
						if robotIF.liftIdle() == true then return "EXIT" end
					end,
				},
			},	-- end of substates of fetch
		},	-- end of fetch
	---------------------------------------------------
		backup = QuantityState:create{
			target = 0.1, speed = robotIF.speedForward,
			enterFunc = robotIF.backup,
			leaveFunc = robotIF.stop,
			exit = "EXIT",
		},
	---------------------------------------------------
	}, -- end of substates of theStateMachine
}	-- end of theStateMachine
---------------------------------------------------------------------------------------
-- Control Loop
---------------------------------------------------------------------------------------
local timeHolding
local stepCount
function init()
	reset()
	timeHolding = robotIF.getTime()	-- in s
	stepCount = 0
	robotIF.disableCamera()

	--robotIF.turnLeft()
end

function step()
	stepCount = stepCount + 1
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding	-- unit s
	timeHolding = timeNow

	print("------- count",stepCount,"time",timePeriod,"------------")
	theStateMachine:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.setVelocity(0,0)
end
