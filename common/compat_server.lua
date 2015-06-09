local fs = require 'pulpo.fs'

_G.scplog = logger.warn

-- extend pairs function to handle IList and IDictionary with standard lua's syntax
function _G.iter(t)
	local tt = type(t)
	if tt == 'cdata' then
		return t:_Iter()
	elseif tt ~= 'table' then
		scplog('type error: should be table or IEnumerable .net object but', type(t), t)
		return
	end
	if t.__IsList__ then -- json unpacked lua table
		return t:Iter()
	else
		return pairs(t)
	end
end

local basepath = debug.getinfo(1).source:match('@(.+)[/¥][^/¥]+$')
function _G.grep(path, pattern, fn, ...)
	fs.scan(basepath.."/../"..path, false, function (f, ...)
		if f:match(pattern) then
			fn(f, ...)
		end
	end, ...)
end

_G.ScriptLoader = {
	SearchPath = basepath.."/../"
}
