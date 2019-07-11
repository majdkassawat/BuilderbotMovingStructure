StateMachine = require("StateMachine")
local QuantityStateMachine = {CLASSQUANTITYSTATEMACHINE = true}
QuantityStateMachine.__index = QuantityStateMachine
setmetatable(QuantityStateMachine,StateMachine)	-- son of StateMachine

function QuantityStateMachine:new(option)
	return self:create(option)
end

function QuantityStateMachine:create(option)
	local instance = StateMachine:create{
		id = option.id,
		data = {
			sum = 0,
			target = 0,
			startTime = nil,

			_target = option.target,
			_speed = option.speed,
			_enterFunc = option.enterFunc,
			_enterPara = option.enterPara,
			_leaveFunc = option.leaveFunc,
			_leavePara = option.leavePara,
			_exit = option.exit,
			_fdataInit = option.fdataInit,
		},
		enterMethod = function(fdata,data,para)
			if data._fdataInit ~= nil then
				data._target = fdata[data._fdataInit].target
				data._speed = fdata[data._fdataInit].speed
				data._enterFunc = fdata[data._fdataInit].enterFunc
				data._enterPara = fdata[data._fdataInit].enterPara
				data._leaveFunc = fdata[data._fdataInit].leaveFunc
				data._leavePara = fdata[data._fdataInit].leavePara
				data._exit = fdata[data._fdataInit].exit
			end

			data.sum = 0
			data.target = data._target
			if type(data._enterFunc) == "function" then data._enterFunc(data._enterPara) end
		end,
		transMethod = function(fdata,data,para)
			if data.sum > data.target then
				return data._exit
			end
			data.sum = data.sum + data._speed * para.time
		end,
		leaveMethod = function(fdata,data,para)
			if type(data._leaveFunc) == "function" then data._leaveFunc(data._leavePara) end
		end,
	}

	return instance
end

return QuantityStateMachine
