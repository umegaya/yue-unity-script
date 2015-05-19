import('Assembly-CSharp') -- disabled for server code
import('UnityEngine')
import('ScriptEngine')
import = function () end -- script writer will be sandboxed by this.

-- compatibility for lua 5.1 and 5.2
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

-- client hack to add lua function method to .net object.
local function set_index_table(obj, mt)
	if type(obj) == 'userdata' then
		-- dotnet metatable replace hack. __index modified
		if mt then
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
	end
end

-- make obj runnable in script system
-- client : add lua function which is defined in corresponding script
ObjectWrapper.Initialize(function (obj, src)
	local scp = src or obj.Type.Script
	if not scp then
		scplog('loadscript error:', 'neither function args nor data provides script path')
		error('script path error')
	end
	local f, err = loadfile(ScriptLoader.SearchPath..scp)
	if not f then
		scplog('loadscript error:', scp, err)
		error(err)
	end
	local mt = f()
	if type(mt) ~= 'table' then
		scplog('loadscript error:', scp, 'returns non-table object')
		error('type error')
	end
	return set_index_table(obj, mt)
end)

-- extend pairs function to handle IList and IDictionary with standard lua's syntax
function _G.iter(t)
	if type(t) == 'userdata' then
		local tp = t:GetType()
		if tp:GetMethod("GetEnumerator") then
			if tp:GetMethod("ContainsKey") then
				return function (it)
					if it:MoveNext() then
						return it.Current.Key, it.Current.Value
					end
				end, t:GetEnumerator()
			else
				return function (it)
					return it:MoveNext() and it.Current or nil
				end, t:GetEnumerator()
			end
		end
	elseif type(t) ~= 'table' then
		scplog('type error: should be table or IEnumerable .net object', type(t))
	end
	return pairs(t)
end

