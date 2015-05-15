local team_base = class.new()

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
	return self.BelongsTo.Count
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

function team_base:display_data()
	return { 
		Id = self.Type.Id,
		Name = self.Type.Name,
		Total = self:count_object(),
		Alive = self:count_alive_object(),
		Score = self.Score,
	}
end
function team_base:pop_point(object)
	return 0, 0
end
function team_base:on_tick()
end

return team_base
