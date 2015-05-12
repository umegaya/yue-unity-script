local object_base = class.new()


function object_base:initialize(data, field)
	self:on_initialize(data, field)
end

function object_base:on_initialize(data, field)
	self.Team = field.Teams[data.TeamId]
	local x, y = self.Team:pop_point(self, field)
	field:enter(self, x, y)
end

function object_base:update(field)
	self:on_tick(field)
end

function object_base:enter_to(cell)
	local p = cell:get_vacant_partition(self)
	if p then
		p:Enter(self)
	end
end

function object_base:exit_from(cell)
	cell:Exit(self)
end

function object_base:move(field, x, y)
	local c = field:CellAt(self.X, self.Y)
	if c then
		self:exit_from(c)
	end
	local nc = field:CellAt(x, y)
	if not nc then
		self:enter_to(c)
		return
	end
	self:enter_to(nc)
end

function object_base:on_tick(field)
end

return object_base
