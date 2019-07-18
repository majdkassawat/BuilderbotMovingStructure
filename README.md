# Builderbot Moving Structure

## Obstacle Avoidance
- A state machine is defined with two simple states; `move_forward`, `turn`. The states depend on information about obstacles given as a list `Obstacles`. 
- The list contains all obstacles seen using the range finder (and in the future the camera). 
- For each obstacle we list the `x,y` position *in reference to the robot*. Assumiing y axis to front, x to the right and origin in the center of the robot.
- In order for us to calculate the positions, a table containing the position, orientation of the range finders in the robot was needed (The current values are estimations based on the model appearance in the simulation)
- The script uses [luafsm] (https://github.com/allsey87/luafsm) which should be in a seperate folder, this seperate folder is in the same directory as *BuilderMovingStructure*
- The script outputs:
    - The list of obstacles with positions 
    - Or a message `No obstacles detected`
*Note: the move functin in this file is not properly defined (still havet figured out the formula yet)*


## Files:
- **004_MajdApproach.lua**: the controller.
- **004_simMajdApproach.argos**: argos configuration file
- **builderbot_rangefinders.xml**: configuration for the range finders, I am not sure if it is used or not to be honest
- **individualData.lua**: I am not sure if it is used or not to be honest
- **pprint.lua**: This is a portable library to print entire tables recursivley (it is quite usefull)
- **RobotInterface.lua**: Harrys wrapper of the robot
- **StateMachine.lua**: this is used by RobotInterface.lua
- **Folder blocktracking**: contains the files for block tracking!!
- **obstacle_avoidance.lua**: contains process obstacles and obstacle avoidance functions and FSM

