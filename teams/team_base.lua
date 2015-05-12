local team_base = class.new()

function team_base:join(object)
	self.BelongsTo[object.Id] = object
	self.TotalPopCount = self.TotalPopCount + 1
end
function team_base:count_alive_object()
	return 0
	--[[
	local count = 0
	for id,obj in iter(self.BelongsTo) do
		if not obj.IsDead then
			count = count + 1						
		end
	end
	return count
	]]
end

function team_base:pop_point(field, object)
	return 0, 0
end
function team_base:on_tick(field)
end

return team_base
