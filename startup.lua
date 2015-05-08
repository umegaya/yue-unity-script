-- TODO : this is time-eater? if so, we need to reuse single lua env.
import('MyAssembly', 'MyNamespace') -- disabled for server code
import = function () end -- script writer will be sandboxed by this.

-- global function (interface to unity3d)
function ScpLog(...)
	print(..., debug.traceback(nil, 2))
end

local field
function Initialize(f, field_data, user_data)
	ScpLog('field_data', field_data)
	ScpLog('user_data', user_data)
	field = f
end

local total_dt = 0
function Update(dt)
	total_dt = total_dt + dt
	if total_dt > 1.0 then
		ScpLog('tick!')
		total_dt = 0
	end
end

function SendCommand(command)
	ScpLog('command', command)
end

