local object_base = class.new()


-- delete/init/update
function object_base:initialize(data)
	self:init_cooldown()
	self:join_team(data.TeamId)
	self:on_initialize(data)
	self:initial_pop()
end
function object_base:initial_pop()
	local x, y = self.Team:pop_point(self)
	GetField():enter(self, x, y)
end
function object_base:on_initialize(data)
end
function object_base:destroy()
	self:leave_team()
	GetField():exit(self)
end
function object_base:update(dt)
	if self:cooldown(dt) then
		self:do_action()
	end
	self:on_tick(dt)
end

-- default cooldown processing
function object_base:init_cooldown()
end
function object_base:cooldown()
	return false
end
function object_base:do_action()
end

-- get data helper
function object_base:current_cell()
	return GetField():CellAt(self.X, self.Y)
end
function object_base:is_friendly(obj)
	return self.Team:is_friendly(obj.Team)
end
function object_base:is_hostile(obj)
	return self.Team:is_hostile(obj.Team)
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
function object_base:enter_to(cell, p)
	p = p or cell:get_vacant_partition(self)
	if p then
		p:Enter(self)
	end
	cell:for_all_user_in_partition(p, function (user, obj)
		user:enter_event(obj)
	end, self)
end
function object_base:exit_from(cell)
	local p = self.Partition
	cell:for_all_user_in_partition(p, function (user, obj)
		user:exit_event(obj)
	end, self)	
	cell:Exit(self)
end

-- returns data for display on client side
function object_base:display_data()
	assert(false, "should be overridden by child class")
end

function object_base:move(x, y)
	local c = GetField():CellAt(self.X, self.Y)
	if not c then
		scplog('invalid current position', self.Id, self.X, self.Y)
		return
	end
	local nc = GetField():CellAt(x, y)
	if not nc then
		scplog('invalid destination', self.Id, x, y)
		return
	end
	self:exit_from(c)
	self:enter_to(nc)
end

function object_base:invoke_command(cmd)
	assert(false, "should overridden by child")
end

function object_base:on_tick()
end

return object_base
