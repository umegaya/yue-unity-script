local fs = require 'pulpo.fs'

_G.scplog = logger.info

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
	if tt == 'cdata' then
		return t:_Iter()
	elseif tt ~= 'table' then
		scplog('type error: should be table or IEnumerable .net object but', type(t), t)
		return
	end
	return pairs(t)
end

local basepath = debug.getinfo(1).source:match('@(.+)[/¥][^/¥]+$')
function _G.grep(path, pattern, fn, ...)
	fs.scan(basepath.."/../"..path, false, function (f, ...)
		if f:match(pattern) then
			fn(f, ...)
		end
	end, ...)
end
