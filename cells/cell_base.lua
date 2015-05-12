local cell_base = class.new()

-- do periodic stuff for this cell
function cell_base:update(field)
	self:on_tick()
	for p in iter(self.UserSide) do
		self:update_partition(p)
	end
	self:update_partition(self.EnemySide)
end
-- do periodic stuff for all partition
function cell_base:update_partition(p)
	for team_id, team in iter(p.Teams) do
		for object in iter(team) do
			self:on_tick_object(object)
			object:update(field, self)
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
function cell_base:for_all_user(fn)
	for p in iter(self.UserSide) do
		for team_id, ulist in iter(p.Users) do
			for u in iter(ulist) do
				local r = fn(u)
				if r then 
					return r 
				end
			end
		end
	end
end
-- pop object from given id
function cell_base:pop(id)
	local o = ObjectFactory.Create(id)
	o:enter_to(self)
end
-- callback
function cell_base:on_tick()
end
function cell_base:on_tick_object(obj)
end

return cell_base