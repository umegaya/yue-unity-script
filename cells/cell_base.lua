local cell_base = class.new()

-- do periodic stuff for this cell
function cell_base:update(dt)
	self:on_tick(dt)
	for p in iter(self.UserSide) do
		self:update_partition(p, dt)
	end
	self:update_partition(self.EnemySide, dt)
end
-- do periodic stuff for all partition
function cell_base:update_partition(p, dt)
	for team_id, team in iter(p.Teams) do
		for object in iter(team) do
			self:on_tick_object(object, dt)
			object:update(dt)
		end
	end
end
-- find vacant partition to enter in, if no room, create new one
function cell_base:get_vacant_partition(o, for_user)
	if o.Type.DisplaySide == "user" then
		for p in iter(self.UserSide) do
			if not (for_user and p.IsFull) then
				return p
			end
		end
		local p = Partition()
		self.UserSide:Add(p)
		return p
	else
		return self.EnemySide
	end		
end
-- iterate function for all user in this cell
function cell_base:iterate_team_list(list, fn, ...)
	for team_id, ulist in iter(list) do
		for u in iter(ulist) do
			local r = fn(u, ...)
			if r then 
				return r 
			end
		end
	end
end
function cell_base:for_all_user(fn, ...)
	for p in iter(self.UserSide) do
		self:iterate_team_list(p.Users, fn, ...)
	end
end
function cell_base:for_all_object(fn, ...)
	for p in iter(self.UserSide) do
		self:iterate_team_list(p.Teams, fn, ...)
	end
	self:iterate_team_list(self.EnemySide.Teams, fn, ...)
end
function cell_base:for_all_object_in_partition(p, fn, ...)
	self:iterate_team_list(p.Teams, fn, ...)
	self:iterate_team_list(self.EnemySide.Teams, fn, ...)
end
function cell_base:for_all_user_in_partition(p, fn, ...)
	self:iterate_team_list(p.Users, fn, ...)
end
-- pop object from given id
function cell_base:pop(id)
	local o = ObjectFactory.Create(id)
	o:enter_to(self)
end
-- returns data for desplay cell
function cell_base:display_data()
	return { 
		Id = self.Type.Id,
		Name = self.Type.Name,
	}
end
-- callback
function cell_base:on_tick(dt)
end
function cell_base:on_tick_object(obj, dt)
end

return cell_base