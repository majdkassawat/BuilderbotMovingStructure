
DEBUG = true

robotIF = require("RobotInterface")
Vec3 = require("Vector3")

pprint = require('pprint')
-- load module

package.path = package.path .. ";../luafsm/luafsm.lua"
luafsm = require("luafsm.luafsm")


---------------------------------------------------------------------------------------
-- Defining range finders positions and orientations
---------------------------------------------------------------------------------------
RangeFinders = {}
RangeFinders[1]={position = {x = 0.01,y = 0.08},angle = 90}
RangeFinders[2]={position = {x = 0.03,y = 0.05},angle = 45}
RangeFinders[3]={position = {x = 0.05,y = 0.01},angle = 0}
RangeFinders[4]={position = {x = 0.05,y = -0.01},angle = 0}
RangeFinders[5]={position = {x = 0.03,y = -0.05},angle = -45}
RangeFinders[6]={position = {x = 0.01,y = -0.08},angle = -90}
RangeFinders[7]={position = {x = -0.01,y = -0.08},angle = -90}
RangeFinders[8]={position = {x = -0.03,y = -0.05},angle = -135}
RangeFinders[9]={position = {x = -0.05,y = -0.01},angle = 180}
RangeFinders[10]={position = {x = -0.05,y = 0.01},angle = 180}
RangeFinders[11]={position = {x = -0.03,y = 0.05},angle = 135}
RangeFinders[12]={position = {x = -0.01,y = 0.08},angle = 90}


function RangeFinderToRobotConversion(distance,range_finder_id)
	x =  RangeFinders[range_finder_id]["position"]["x"] + math.cos(math.rad(RangeFinders[range_finder_id]["angle"])) * distance
	y =  RangeFinders[range_finder_id]["position"]["y"] + math.sin(math.rad(RangeFinders[range_finder_id]["angle"])) * distance
	return x,y
end

---------------------------------------------------------------------------------------
-- Process Obstacles
---------------------------------------------------------------------------------------
Obstacles = {}

function ProcessObstacles()
	-- Loop over range finders and register obstacles and there positions relative to the robot. 
	-- The position is in x,y. y is pointing to the front of the robot and x to the right.
	Obstacles = {}
	for i = 1,12 do
		distance = robotIF.getRFReading(i)
		-- print(distance)
		if distance > 0 then 
			obstacle_x,obstacle_y = RangeFinderToRobotConversion(distance,i)
			table.insert(Obstacles,{position = {x = obstacle_x,y = obstacle_y},id = nil})
		end	
	end
	if #Obstacles == 0 then print("No obstacles detected") else pprint("Obstacles list",Obstacles) end 
end
---------------------------------------------------------------------------------------
-- Move
---------------------------------------------------------------------------------------
function move(velocity ,bearing)	-- still havent defined the bearing well
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
move_forward_state = function ()
	--if there is an obstacle infront, return true and turn
	if Obstacles ~= nil then
		for key,obstacle in pairs(Obstacles) do
			if obstacle["position"]["y"] > 0.05 then
				return true, "turn"
			end
		end
		-- print("move forward")
		move(0.06,0)
	end
end
turn_state = function ()
	-- print("turning")
	move(0.03,0.01)
	return true,"move_forward"
end
obstacle_avoidance_states = {
	entry = "move_forward",
	substates = {
	  move_forward	= move_forward_state,
	  turn = turn_state,
	}
  }
  
---------------------------------------------------------------------------------------
-- Control Loop
---------------------------------------------------------------------------------------
local timeHolding
local stepCount
function init()
	reset()	
	-- instantiate the state machine
	obstacle_avoidance_fsm = luafsm.create(obstacle_avoidance_states)
end

function step()
	stepCount = stepCount + 1
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding	-- unit s
	timeHolding = timeNow
	ProcessObstacles()
	obstacle_avoidance_fsm()
	
end

function reset()
	timeHolding = robotIF.getTime()	-- in s
	stepCount = 0
	-- robotIF.enableCamera()
	robotIF.setLiftPosition(0.15)

end

function destroy()
	robotIF.setVelocity(0,0)
end
