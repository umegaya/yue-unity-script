local object_base = behavior.new()


-- delete/init/update
function object_base:initialize(data)
	self:init_cooldown()
	self:join_team(data.TeamId)
	self:on_initialize(data)
	self.Field.ObjectMap:Add(self.Id, self)
end
function object_base:on_initialize(data)
end
function object_base:destroy()
	self:leave_team()
	self:exit_from(self:current_cell())
	self.Field.ObjectMap:Remove(self.Id)
end
function object_base:update(dt)
	if self:cooldown(dt) then
		local wait = self:do_action()
        self:set_cooldown(wait)
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
	return self.Field:CellAt(self.X, self.Y)
end
function object_base:is_friendly(obj)
	return self.Team:is_friendly(obj.Team)
end
function object_base:is_hostile(obj)
	return self.Team:is_hostile(obj.Team)
end

-- join/leave team
function object_base:join_team(team_id)
	self.Team = self.Field.Teams[team_id]
	self.Team:join(self)
end
function object_base:leave_team()
	self.Team:leave(self)
end

-- enter/exit field
function object_base:enter_to(cell, p)
	if self.Type.DisplaySide == "user" then
		p = p or cell:get_vacant_partition(self)
		if p then
			p:Enter(self)
		end
		cell:for_all_user_in_partition(p, function (user, obj)
			user:enter_event(obj)
		end, self)
	else
		cell.EnemySide:Enter(self)
		cell:for_all_user(function (user, obj)
			user:enter_event(obj)
		end, self)
	end
end
function object_base:exit_from(cell)
	if self.Type.DisplaySide == "user" then
		local p = self.Partition
		cell:for_all_user_in_partition(p, function (user, obj)
			user:exit_event(obj)
		end, self)	
		p:Exit(self)
	else
		cell:for_all_user(function (user, obj)
			user:exit_event(obj)
		end, self)
		cell.EnemySide:Exit(self)
	end
end

function object_base:for_all_visible_object(fn, ...)
	local cell = self:current_cell()
	if self.Type.DisplaySide == "user" then
		-- my partition and enemyside
		return cell:iterate_team_list(self.Partition.Teams, fn, ...) or 
			cell:iterate_team_list(cell.EnemySide.Teams, fn, ...)
	else
		-- enemy side can see all object
		return cell:for_all_object(fn, ...)
	end
end
function object_base:choose_random_visible_object(filter, ...)
	local cell = self:current_cell()
	local cand = {}
	if self.Type.DisplaySide == "user" then
		-- my partition and enemyside
		cell:iterate_team_list(self.Partition.Teams, filter, cand, ...)
		cell:iterate_team_list(cell.EnemySide.Teams, filter, cand, ...)
	else
		-- enemy side can see all object, so first choose random user side partition
		-- to reduce iteration count
		local p = cell:random_partition()
		if p then
			cell:iterate_team_list(p.Teams, filter, cand, ...)
		end
		cell:iterate_team_list(cell.EnemySide.Teams, filter, cand, ...)
	end
	return #cand > 0 and cand[math.random(1, #cand)]
end
function object_base:for_all_visible_user(fn, ...)
	local cell = self:current_cell()
	if self.Type.DisplaySide == "user" then
		-- my partition
		return cell:iterate_team_list(self.Partition.Users, fn, ...)
	else
		-- enemy side can see all object
		return cell:for_all_user(fn, ...)
	end
end

-- event notifier
function object_base:action_event(target, action_result)
    local cell = self:current_cell()
	local p
	if target.Type.DisplaySide == "user" then 
		p = target.Partition
	elseif action_result:has_invoker() then
		p = action_result:object_arg(1).Partition
	end
	if p then
	    cell:for_all_user_in_partition(p, function (user, t, ar)
		   return user:action_event(t, ar) 
	    end, target, action_result)
	else
		-- non-invoker result does something to npc. it is visible for all user in this cell 
		-- TODO : but it may too heavy for crowded cell, then how we handle that?
		cell:for_all_user(function (user, t, ar)
		   return user:action_event(t, ar) 
	    end, target, action_result)
	end
end
function object_base:dead_event(target)
    self:for_all_visible_user(function (user, t)
	   return user:dead_event(t) 
    end, target)
end
function object_base:status_change_event(target)
    self:for_all_visible_user(function (user, t)
	   return user:status_change_event(t) 
    end, target)
end

-- returns data for display on client side
function object_base:display_data()
	assert(false, "should be overridden by child behavior")
end

function object_base:move(x, y)
	local c = self.Field:CellAt(self.X, self.Y)
	if not c then
		scplog('invalid current position', self.Id, self.X, self.Y)
		return
	end
	local nc = self.Field:CellAt(x, y)
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
