
DEBUG = true

robotIF = require("RobotInterface")
Vec3 = require("Vector3")
Matrix = require("Matrix")
Vector = require("Vector")
pprint = require('pprint')
-- load module

-- package.path = package.path .. ";../luafsm/luafsm.lua"
-- luafsm = require("luafsm.luafsm")
-- package.path = package.path .. ";../luabt/luabt.lua"
luabt = require("luabt.luabt")

---------------------------------------------------------------------------------------
-- Defining range finders positions and orientations
---------------------------------------------------------------------------------------
RangeFinders = {}
RangeFinders[1]={position = {x = 0.0640,y = -0.0175,z = 0.0495},angle = 90}
RangeFinders[2]={position = {x = 0.0523,y = -0.0522,z = 0.0495},angle = 135}
RangeFinders[3]={position = {x = 0.0175,y = -0.0640,z = 0.0495},angle = 180}
RangeFinders[4]={position = {x = -0.0175,y = -0.0640,z = 0.0495},angle = 180}
RangeFinders[5]={position = {x = -0.0522,y = -0.0523,z = 0.0495},angle = -135}
RangeFinders[6]={position = {x = -0.0640,y = -0.0175,z = 0.0495},angle = -90}
RangeFinders[7]={position = {x = -0.0640,y = 0.0175,z = 0.0495},angle = -90}
RangeFinders[8]={position = {x = -0.0522,y = 0.0523,z = 0.0495},angle = -45}
RangeFinders[9]={position = {x = -0.0175,y = 0.0640,z = 0.0495},angle = 0}
RangeFinders[10]={position = {x = 0.0175,y = 0.0640,z = 0.0495},angle = 0}
RangeFinders[11]={position = {x = 0.0523,y = 0.0522,z = 0.0495},angle = 45}
RangeFinders[12]={position = {x = 0.0640,y = 0.0175,z = 0.0495},angle = 90}


function RangeFinderToRobotConversion(distance,range_finder_id)
	y =  RangeFinders[range_finder_id]["position"]["y"] + math.cos(math.rad(RangeFinders[range_finder_id]["angle"])) * distance
	x =  RangeFinders[range_finder_id]["position"]["x"] + math.sin(math.rad(RangeFinders[range_finder_id]["angle"])) * distance
	z =  RangeFinders[range_finder_id]["position"]["z"]
	return x,y,z
end


function Camera2RobotConversion(loc)	
	-- compute the location of Box in Robot's coordinate system
	-- robot Axis : x front y left z up
	-- camera Axis : x right y down z far
	

	CamTranslation = Vec3:create( 0.1, 0, robotIF.getLiftPosition() + 0.1495)		
	alpha = math.rad(135)
	lambda = math.rad(90)

	local RotMatX = Matrix:create{
		{1, 0              , 0                 },
		{0, math.cos(alpha), math.sin(alpha)},
		{0, -1*math.sin(alpha), math.cos(alpha)},
	}

	local RotMatZ = Matrix:create{
		{math.cos(lambda), math.sin(lambda), 0},
		{-1*math.sin(lambda), math.cos(lambda)   , 0},
		{0               , 0                  , 1},
	}
	
	local v_loc = Vector:create({loc.x, loc.y, loc.z})	
	local R = RotMatZ * RotMatX 
	-- pprint(R)
	local locVec = R * v_loc

	local locVec3 = Vec3:create(locVec[1],locVec[2],locVec[3])
	locVec3 = locVec3 + CamTranslation
	
	return locVec3
end
---------------------------------------------------------------------------------------
-- Process Obstacles
---------------------------------------------------------------------------------------
Obstacles = {}

function ProcessObstacles()
	
		
	if robotIF.getLiftPosition() > 0.05 then 
		-- Loop over range finders and register obstacles and there positions relative to the robot. 
		-- The position is in x,y,z. x is pointing to the front of the robot, y to the left and z up.
		Obstacles = {}
		for i = 1,12 do
			distance = robotIF.getRFReading(i)
			-- print(distance)
			if distance > 0 then 
				obstacle_x,obstacle_y,obstacle_z = RangeFinderToRobotConversion(distance,i)
				table.insert(Obstacles,{position = {x = obstacle_x,y = obstacle_y,z = obstacle_z},id = nil})
			end	
		end
	else
		return false
	end
		
	local Tags,Boxes = robotIF.getBoxes()
	for i = 1,Boxes.n do 
		obstacle_position_vector_camera = Vec3:create( Boxes[i].translation.x, Boxes[i].translation.y, Boxes[i].translation.z)
		obstacle_position_vector_robot =  Camera2RobotConversion(obstacle_position_vector_camera)
		obstacle_id = Boxes[i].label
		table.insert(Obstacles,{position = obstacle_position_vector_robot,id = obstacle_id})
	end

	if #Obstacles == 0 then print("No obstacles detected") else pprint("Obstacles list",Obstacles) end

	return true
	
end
---------------------------------------------------------------------------------------
-- Move
---------------------------------------------------------------------------------------
function move(velocity ,bearing)	-- still have not defined the bearing well
	if bearing == 0 then 
		robotIF.setVelocity(velocity,-velocity)
	elseif bearing > 0 then
		robotIF.setVelocity(velocity,velocity)
	elseif bearing < 0 then 
		robotIF.setVelocity(-velocity,-velocity)
	end
end
---------------------------------------------------------------------------------------
-- Obstacle avoidance
---------------------------------------------------------------------------------------
-- define the state machine and its functions
-- move_forward_state = function ()
-- 	--if there is an obstacle infront, return true and turn
-- 	if Obstacles ~= nil then
-- 		for key,obstacle in pairs(Obstacles) do
-- 			if obstacle["position"]["x"] > 0.04 then
-- 				return true, "turn"
-- 			end
-- 		end
-- 		-- print("move forward")
-- 		move(0.06,0)
-- 	end
-- end
-- turn_state = function ()
-- 	-- print("turning")
-- 	move(0.03,0.01)
-- 	return true,"move_forward"
-- end
-- obstacle_avoidance_states = {
-- 	entry = "move_forward",
-- 	substates = {
-- 	  move_forward	= move_forward_state,
-- 	  turn = turn_state,
-- 	}
--   }

-- define obstacle avoidance behaviour tree
obstacle_avoidance_node = {
	type = "selector",
	children = {

		{	-- This is the obstacle avoidance sequence
			type = "sequence",
			children = {
				-- condition leaf, is there an obstacle?
				function()
					if Obstacles ~= nil then
						for key,obstacle in pairs(Obstacles) do
							if obstacle["position"]["x"] > 0.04 then
								return false, true
							end
						end
						return false, false
					end
				end,
				-- action leaf, turn away
				function()
					print("turning")
					move(0.03,0.01)
					return true
				end,
			}
	   },
	   	-- action leaf, move forward and print
		function()
			print("Moving forward")
			move(0.06,0)
			return true -- (Running)
		end,

	}
 }
---------------------------------------------------------------------------------------
-- Control Loop
---------------------------------------------------------------------------------------
local timeHolding
local stepCount
function init()
	reset()	
	-- initiate the state machine
	-- obstacle_avoidance_fsm = luafsm.create(obstacle_avoidance_states)

	-- instantiate a behavior tree
	obstacle_avoidance_bt = luabt.create(obstacle_avoidance_node)


end

function step()
	stepCount = stepCount + 1
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding	-- unit s
	timeHolding = timeNow
	if ProcessObstacles() == true then -- if updating the list of obstacles was successful
		-- obstacle_avoidance_fsm()

		-- tick the behavior tree until it has finished (running == false)
		obstacle_avoidance_bt()
	end
	
end

function reset()
	timeHolding = robotIF.getTime()	-- in s
	stepCount = 0
	robotIF.enableCamera()
	robotIF.setLiftPosition(0.15)

end

function destroy()
	robotIF.setVelocity(0,0)
end
