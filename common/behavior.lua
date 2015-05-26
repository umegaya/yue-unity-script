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

-- create new behavior instance
function _M.new(parent, ...)
	local t = {}
	t.__index = t
	if parent then
		table.merge(t, parent)
	end
	if select('#', ...) > 0 then
		_M.mix(t, ...)
	end
	return t
end

-- mix (override same name method) 
-- arbiter number of behaviors. 
function _M.mix(...)
	local n = select('#', ...)
	if n <= 0 then 
		return {} 
	end
	local r = select(1, ...)
	for i=2,n do
		local t = select(i, ...)
		table.merge(r, t)
	end
	return r
end

return _M
