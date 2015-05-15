local object_base = class.new()


-- delete/init/update
function object_base:initialize(data)
	self:on_initialize(data)
end
function object_base:on_initialize(data)
	self:join_team(data.TeamId)
	local x, y = self.Team:pop_point(self)
	GetField():enter(self, x, y)
end
function object_base:destroy()
	self:leave_team()
	GetField():exit(self)
end
function object_base:update()
	self:on_tick()
end

-- join/leave team
function object_base:join_team(team_id)
	self.Team = GetField().Teams[team_id]
	self.Team:join(self)
end
function object_base:leave_team()
	self.Team:leave(self)
end

-- enter/exit field
function object_base:enter_to(cell)
	local p = cell:get_vacant_partition(self)
	if p then
		p:Enter(self)
	end
end
function object_base:exit_from(cell)
	cell:Exit(self)
end

-- returns data for display on client side
function object_base:display_data()
	assert(false, "should be overridden by child class")
end

function object_base:move(x, y)
	local c = GetField():CellAt(self.X, self.Y)
	if c then
		self:exit_from(c)
	end
	local nc = GetField():CellAt(x, y)
	if not nc then
		self:enter_to(c)
		return
	end
	self:enter_to(nc)
end

function object_base:on_tick()
end

return object_base
