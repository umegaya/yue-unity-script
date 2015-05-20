local group_base = class.new()

function group_base:on_apply_to(cell, team_id)
	local cnt = 0
	local data = { TeamId = team_id }
	for id in iter(self.Type.FixedList) do
		local o = ObjectFactory.Create(id)
		o:initialize(data)
		cnt = cnt + 1
	end
	if cnt < self.Type.Size then
		local rlist = self.Type.RandomList
		for i=cnt+1, self.Type.Size do
			local id = rlist[math.random(0, rlist.Count - 1)]
			local o = ObjectFactory.Create(id)
			o:initialize(data)
		end
	end
end

return group_base
