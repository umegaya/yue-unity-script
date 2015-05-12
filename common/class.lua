local _M = {}

function table.merge(self, t, deep)
	if type(t) ~= 'table' then
		return
	end
	for k,v in pairs(t) do
		if deep and type(self[k]) == 'table' then
			self[k]:merge(v)
		else
			self[k] = v
		end
	end
end

-- create new class instance
function _M.new()
	local t = {}
	t.__index = t
	return t
end

-- mix (override same name method) 
-- arbiter number of classes. 
function _M.mix(...)
	local n = select('#', ...)
	if n <= 0 then 
		return {} 
	end
	local r = select(1, ...)
	for i=2,n do
		local t = select(i, ...)
		r:merge(t)
	end
	return r
end

return _M
