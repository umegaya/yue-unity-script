import('Assembly-CSharp') -- disabled for server code
import('UnityEngine')
import('ScriptEngine')
import('System.IO')
import = function () end -- script writer will be sandboxed by this.

-- compatibility for lua 5.1 and 5.2
_G.unpack = table.unpack

-- global function (interface to unity3d)
if DEBUG then
	function scplog(...)
		local data = {...}
		local last_index = (select('#', ...) + 1)
		for i=1,last_index-1 do
			if not data[i] then
				data[i] = (data[i] == false and "false" or "nil")
			end
		end
		data[last_index] = debug.traceback(nil, 2)
		print(unpack(data, 1, last_index))
	end
else
	function scplog(...)
	end
end

-- extend pairs function to handle IList and IDictionary with standard lua's syntax
function _G.iter(t)
	local tt = type(t)
	if tt == 'userdata' then
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
	elseif tt ~= 'table' then
		scplog('type error: should be table or IEnumerable .net object but', type(t), t)
		return
	end
	if t.__IsList__ then
		return t:Iter()
	else
		return pairs(t)
	end
end

function _G.grep(path, pattern, fn, ...)
	local di = DirectoryInfo(ScriptLoader.SearchPath..path)
	local list = di:GetFiles("*.lua", SearchOption.AllDirectories)
	for f in iter(list) do
		fn(f.FullName, ...)
	end
end
