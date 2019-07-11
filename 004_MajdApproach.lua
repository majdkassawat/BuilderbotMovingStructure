--[[
--	for Michael's manipulator
--]]
DEBUG = true


robotIF = require("RobotInterface")
Vec3 = require("Vector3")

pprint = require('pprint')


---------------------------------------------------------------------------------------
-- Random walk with obstacle avoidance
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Trajectory definition
---------------------------------------------------------------------------------------
-- The trajectory consists in multiple target points, 
-- For each point we define:
-- * The used reference frame (based on robots sensors)
-- * The corrections: 
-- 	*type: describes how to apply the correction
-- 	*axis: the axis in which the correctin should be made
--	*target: the target value that we need to reach, according to the reference given
--	*error_tolerance: the tolerance for each correction
--	*controller_parameters: parameters for the pid controller or other parameters used for the control
--	*finished flag: marks when the correctin is done or not 
--This is an abstract way to implement the planning for the robot.
--It provides an interface for mixing different types of control in the same trajectory. 
--One correction could consist of multiple subcorrections each has its own parameters and target value


current_vel_linear = 0
current_vel_angular = 0
crnt_trgt_pnt_idx = 0

references = {}

trajectory_plan = {[0] = {},[1] = {}} 
trajectory_plan[0]["reference"] = 1
trajectory_plan[0]["reached"] = false
trajectory_plan[0]["corrections"] = {}
trajectory_plan[0]["corrections"]["type"] = "single"
trajectory_plan[0]["corrections"]["axis"] = "x"
trajectory_plan[0]["corrections"]["error_tolerance"] = 0.002
trajectory_plan[0]["corrections"]["controller_parameters"] = {
    k= 0.04, bias= 0}
trajectory_plan[0]["corrections"]["target"] = -0.1
trajectory_plan[0]["corrections"]["finished"] = false


trajectory_plan[1]["reference"] = 1
trajectory_plan[1]["reached"] = false
trajectory_plan[1]["corrections"] = {type = "parallel", finished = false, [0]={} ,[1]={} }
trajectory_plan[1]["corrections"][0]["type"] = "single"
trajectory_plan[1]["corrections"][0]["axis"] = "z"
trajectory_plan[1]["corrections"][0]["error_tolerance"] = 0.002
trajectory_plan[1]["corrections"][0]["controller_parameters"] = {
    k= 0.05, bias= 0.01}
trajectory_plan[1]["corrections"][0]["target"] = 0.15
trajectory_plan[1]["corrections"][0]["finished"] = false
trajectory_plan[1]["corrections"][1]["type"] = "single"
trajectory_plan[1]["corrections"][1]["axis"] = "alpha"
trajectory_plan[1]["corrections"][1]["error_tolerance"] = 0.002
trajectory_plan[1]["corrections"][1]["controller_parameters"] = {
    k= 0.002, bias= 0.0001}
trajectory_plan[1]["corrections"][1]["target"] = 0
trajectory_plan[1]["corrections"][1]["finished"] = false
---------------------------------------------------------------------------------------
-- Process correction 
---------------------------------------------------------------------------------------
function process_correction(reference_index, correction)
	pprint("correction: ",correction)
    if correction["type"] == "single" then
        error = references[reference_index][correction["axis"]]-correction["target"]
		k = correction["controller_parameters"]["k"]
        bias = correction["controller_parameters"]["bias"]
		error_tolerance = correction["error_tolerance"]
        target_vel = (error) * k + (error)/math.abs(error) * bias
        print(correction["axis"],"error:",error)
        if correction["axis"] == "z" then
        	--correct z
            if(math.abs(error) > error_tolerance) then
                current_vel_linear = target_vel
                correction["finished"] = false
            else 
                current_vel_linear = 0
				correction["finished"] = true
			end
        elseif correction["axis"] == "alpha" then
            -- correct roll
            if(math.abs(error) > error_tolerance) then
                current_vel_angular = target_vel
                correction["finished"] = false
            else
                current_vel_angular = 0
				correction["finished"] = true
			end
		elseif correction["axis"] == "x" then
            -- correct x using rotation
            if(math.abs(error) > error_tolerance) then
                current_vel_angular = target_vel
                correction["finished"] = false
            else
                current_vel_angular = 0
				correction["finished"] = true
			end

		end

    elseif correction["type"] == "parallel" then
		correction["finished"] = true
        for i = 0, #correction do 
            process_correction(reference_index, correction[i])
            if correction[i]["finished"] == false then
				correction["finished"] = false
			end
		end
	end
	return correction["finished"]
end	

function stop()
    current_vel_linear = 0
	current_vel_angular = 0
end
function move()
	
	-- print("box in sight: ",)
	local Tags,Boxes = robotIF.getBoxes()
	pprint.setup {
		show_all = false,
		wrap_array = true,
	}
	
	if robotIF.boxInsight() == true then --for now we take only one box and one tag, the tag is chosen to be from the side (no selection process between two side tags for now)
		tag_id = -1
		for i=1,Boxes[1].nTags do --check if there is any tag detected
			if Boxes[1][i].rotation.y < 0 then --check if one of tags detected is a side tag
				tag_id=i
			end
		end
		if tag_id == -1 then --check if one of tags detected is a side tag
			print("processing point and no tags found")
			stop()
		else
			--create the reference to be used with the corrections (with the important data only)
			references[1]={x = Boxes[1][tag_id].translation.x, z = Boxes[1][tag_id].translation.z,alpha = Boxes[1][tag_id].rotation.x}
			pprint("reference: ",references[1])
			if crnt_trgt_pnt_idx <= #trajectory_plan then
				current_point = trajectory_plan[crnt_trgt_pnt_idx]
				-- found some markers
				if current_point["reached"] == true then  -- point has already been reached
					crnt_trgt_pnt_idx = crnt_trgt_pnt_idx + 1  -- move to next point
				else  -- point has not been processed yet
					print("processing point and found tag,point index: " , crnt_trgt_pnt_idx)
					current_point["reached"] = process_correction(
						current_point["reference"], current_point["corrections"])
				end
			else  --reached the end of the trajectory
				print("reached end of trajectory")
				stop()
			end
		end
	else
		print("processing point and no tags found")
		stop()
	end 
end 
---------------------------------------------------------------------------------------
-- Control Loop
---------------------------------------------------------------------------------------
local timeHolding
local stepCount
function init()
	reset()
	timeHolding = robotIF.getTime()	-- in s
	stepCount = 0
	robotIF.enableCamera()
	robotIF.setLiftPosition(0.05)

	
end

function step()
	stepCount = stepCount + 1
	local timeNow = robotIF.getTime()
	local timePeriod = timeNow - timeHolding	-- unit s
	timeHolding = timeNow
	move()
	--Here we should have a mixer
	robotIF.setVelocity(current_vel_angular+current_vel_linear,current_vel_angular-current_vel_linear)
	print("------- count",stepCount,"time",timePeriod,"------------")
	-- theStateMachine:step{time = timePeriod}
end

function reset()
end

function destroy()
	robotIF.setVelocity(0,0)
end
