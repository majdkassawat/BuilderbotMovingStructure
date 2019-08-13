
DEBUG = true

robotIF = require("RobotInterface")
Vec3 = require("Vector3")
Matrix = require("Matrix")
Vector = require("Vector")
pprint = require('pprint')
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
-- Process Blocks
---------------------------------------------------------------------------------------
--	We are asinging type = "target" to all of the blocks, I did not know how to read the LEDs
Blocks = {}
function ProcessBlocks()
	Blocks = {}
	local Tags,Boxes = robotIF.getBoxes()
	for i = 1,Boxes.n do 
		block_position_vector_camera = Vec3:create( Boxes[i].translation.x, Boxes[i].translation.y, Boxes[i].translation.z)
		block_position_vector_robot =  Camera2RobotConversion(block_position_vector_camera)
		block_type = "target"
		block_id = Boxes[i].label
		table.insert(Blocks,{position = block_position_vector_robot,id = block_id,type = block_type})
	end
end
---------------------------------------------------------------------------------------
-- Process Obstacles
---------------------------------------------------------------------------------------
Obstacles = {}

function ProcessObstacles()
		
	if robotIF.getLiftPosition() > 0.05 then --	checks if the gripper is up
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
	--	Consider non-target blocks as obstacles
	for key,block in pairs(Blocks) do 
		if block["type"] ~= "target" then
			table.insert(Obstacles,{position = block["position"],id = block["id"]})
		end
	end

	-- if #Obstacles == 0 then print("No obstacles detected") else pprint("Obstacles list",Obstacles) end

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



move_forward = function()
	-- Move forward function
	move(0.02,0)
	return true
end
turn_left = function()
	-- Turn left function
	move(0.01,1)
	return true
end
turn_right = function()
	-- Turn right function
	move(0.01,-1)
	return true
end
stop = function()
	move(0,1)
	return true
end


-- Define obstacle avoidance behaviour tree
obstacle_avoidance = {
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
								print("avoiding obstacles")
								return false, true
							end
						end
						return false, false
					else 
						return false, false
					end
				end,
				-- action leaf, turn away
				turn_left,
			}
	   },
	   	-- action leaf, move forward
		-- move_forward

	}
 }

---------------------------------------------------------------------------------------
-- Approach Cube 
---------------------------------------------------------------------------------------
-- In this tree we are supposed to use blocks rather than obstacles list (I will change it later)
target_cube_detected = function()
	if Blocks ~= nil then
		for key,block in pairs(Blocks) do 
			if block["type"] == "target" then
				print("detected target")
				return false, true
			end
		end
		return false, false
	else
		return false, false
	end
end
check_approached_cube = function()
	--	This only checks if the robot has approached the cube but still seeing the cube (yet not ready for picking)
	-- print("checking reached")
	target_distance = 0.22
	error_tolerance = 0.01
	-- pprint(Blocks)
	for key,block in pairs(Blocks) do 
		actual_distance = block["position"]["x"]
		-- print(actual_distance)
		if block["type"] == "target" then
			error = target_distance - actual_distance
			if math.abs(error) < error_tolerance then
				print("reached target")
				return false, true
			else return false, false
			end
		else print("lost target")
		end
	end
end

check_current_approach_angle_bigger = function()
	-- Checks if the current angle is bigger than the required calculated approach angle
	-- For now the approach angle is set to zero at all times since we do not have a correct cube orientation
	-- print("check bigger")
	target_angle = 0
	error_tolerance = 0.03
	for key,block in pairs(Blocks) do 
		actual_angle = math.atan(block["position"]["y"]/block["position"]["x"]) 
		-- print(actual_angle)
		if block["type"] == "target" then
			error = target_angle - actual_angle
			if (error < 0) and (math.abs(error) >  error_tolerance)  then
				return false, true
			else return false, false
			end
		else print("lost target")
		end
	end
end
check_current_approach_angle_smaller = function()
	-- Checks if the current angle is smaller than the required calculated approach angle
	-- For now the approach angle is set to zero at all times since we do not have a correct cube orientation
	-- print("check smaller")
	target_angle = 0
	error_tolerance = 0.01
	for key,block in pairs(Blocks) do 
		actual_angle = math.atan(block["position"]["y"]/block["position"]["x"]) 
		-- print(actual_angle)
		if block["type"] == "target" then
			error = target_angle - actual_angle
			if (error > 0) and (math.abs(error) >  error_tolerance)  then
				return false, true
			else return false, false
			end
		else print("lost target")
		end
	end
end


approach = {	
	type = "selector",
	children = {
		check_approached_cube,
		{
			type = "selector",
			children = {
				{
					type = "selector",
					children = {
						{
							type = "sequence",
							children = {
								check_current_approach_angle_bigger,
								turn_right
							}
						},
						{
							type = "sequence",
							children = {
								check_current_approach_angle_smaller,
								turn_left
							}
						}
					}
				},
				move_forward
			}
		}
	}
}

detect_and_approach_target = {
	type = "sequence",
	children = {
		target_cube_detected,
		approach,
		stop,
		--pickup
	}
}

main_node = { 
	type = "selector",
	children = {
		obstacle_avoidance,
		detect_and_approach_target,
		move_forward,
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
	--obstacle_avoidance_bt = luabt.create(obstacle_avoidance_node)
	main_bt = luabt.create(main_node)


end

function step()
	stepCount = stepCount + 1
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding	-- unit s
	timeHolding = timeNow
	ProcessBlocks()
	if ProcessObstacles() == true then -- if updating the list of obstacles was successful
		-- obstacle_avoidance_fsm()

		-- tick the behavior tree until it has finished (running == false)
		-- obstacle_avoidance_bt()
		main_bt()
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
