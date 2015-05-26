local group_base = behavior.new()

function group_base:on_apply_to(cell, team_id)
	local cnt = 0
	local data = { TeamId = team_id }
	for id in iter(self.Type.FixedList) do
		cell:pop(id, data)
		cnt = cnt + 1
	end
	if cnt < self.Type.Size then
		local rlist = self.Type.RandomList
		for i=cnt+1, self.Type.Size do
			local id = rlist:GetRandom()
			cell:pop(id, data)
		end
	end
end

return group_base
