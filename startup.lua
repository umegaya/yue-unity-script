-- TODO : this is time-eater? if so, we need to reuse single lua env.
if import then
	import('Assembly-CSharp') -- disabled for server code
	import('ScriptEngine')
	import = function () end -- script writer will be sandboxed by this.
else
	ServerMode = true
	_G.scplog = logger.info
end

-- compatibility for lua 5.1 and 5.2 omg...
_G.unpack = table.unpack

-- global function (interface to unity3d)
if DEBUG then
	function scplog(...)
		local data = {...}
		local last_index = (select('#', ...) + 1)
		data[last_index] = debug.traceback(nil, 2)
		if data[1] then
			print(unpack(data, 1, last_index))
		else
			print("nil", data[last_index])
		end
	end
else
	function scplog(...)
	end
end


function _G.setmetatable(obj, mt)
	if type(obj) == 'userdata' then
		-- dotnet metatable replace hack. only __index can be applied
		if mt.__index then
			local orig_mt = debug.getmetatable(obj)
			local orig_index = orig_mt.__index
			function orig_mt.__index(t, k)
				local v = rawget(mt, k)
				return v or orig_index(t, k)
			end
		else
			scplog('warn: only __index can be applied to .NET objects')
		end
		return obj
	else
		return debug.setmetatable(obj, mt)
	end
end


-- TODO : above here have to move client only script (client_compat.lua)
local field_data_mt = {}
field_data_mt.__index = field_data_mt
function field_data_mt:iter()
	return self:GetEnumerator()
end

local field
function Initialize(f, field_data, user_data)
	scplog('initialize: field_data', field_data)
	field = f
	setmetatable(field_data, field_data_mt)
	local it = field_data:iter()
	while it:MoveNext() do
		print(it.Current)
		f.Objectives:Add(ObjectiveFactory.Create(it.Current))
	end
end

function Enter(id, peer, user_data)
	-- create user by peer and id. data is initialized by user_data
	if ServerMode then
		-- TODO : on server mode, user data is untrusted, so query webserver to real userdata.
	else
		scplog('enter: user_data', user_data)
	end
	peer:Play("start play event")
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

