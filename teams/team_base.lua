local team_base = behavior.new()

function team_base:join(object)
	self.BelongsTo[object.Id] = object
end
function team_base:join_user(u)
	self.UserBelongsTo[u.Id] = u
end
function team_base:leave(object)
	self.BelongsTo:Remove(object.Id)
end 
function team_base:leave_user(u)
	self.UserBelongsTo:Remove(u.Id)
end 
function team_base:count_object()
	return self.BelongsTo:Size()
end
function team_base:count_alive_object()
	local count = 0
	for id,obj in iter(self.BelongsTo) do
		if not obj.IsDead then
			count = count + 1						
		end
	end
	return count
end
function team_base:is_friendly(team)
	for id in iter(self.Type.FriendlyTeams) do
		if team.Type.Id == id then
			return true
		end
	end
end
function team_base:is_hostile(team)
	for id in iter(self.Type.HostileTeams) do
		if team.Type.Id == id then
			return true
		end
	end
end

function team_base:display_data()
	return { 
		Id = self.Type.Id,
		Name = self.Type.Name,
		Total = self:count_object(),
		UserTotal = self.UserBelongsTo:Size(),
		Alive = self:count_alive_object(),
		Score = self.Score,
	}
end
function team_base:pop_point(object)
	return 0, 0
end
function team_base:on_tick(dt)
end

return team_base
