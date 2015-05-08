-- TODO : this is time-eater? if so, we need to reuse single lua env.
if import then
	import('MyAssembly', 'MyNamespace') -- disabled for server code
	import = function () end -- script writer will be sandboxed by this.
else
	ServerMode = true
end

-- compatibility for lua 5.1 and 5.2 omg...
_G.unpack = table.unpack

-- global function (interface to unity3d)
if DEBUG then
	function scplog(...)
		local data = {...}
		local last_index = (select('#', ...) + 1)
		data[last_index] = debug.traceback(nil, 2)
		print(unpack(data, 1, last_index))
	end
else
	function scplog(...)
	end
end

local field
function Initialize(f, field_data, user_data)
	scplog('initialize: field_data', field_data)
	field = f
end

function Enter(user_data)
	if ServerMode then
		-- TODO : on server mode, user data is untrusted, so query webserver to real userdata.
	else
		scplog('enter: user_data', user_data)
	end
end

local total_dt = 0
function Update(dt)
	total_dt = total_dt + dt
	if total_dt > 1.0 then
		scplog('tick!')
		total_dt = 0
	end
end

function SendCommand(command)
	scplog('command', command)
end

