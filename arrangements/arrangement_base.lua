local arrangement_base = class.new()

function arrangement_base:fill_random(team_id,candidates)
	for id in iter(candidates) do
		local g = GroupFactory.Create(id)
		local cell = GetField():random_cell()
		g:on_apply_to(cell, team_id)
	end
end

function arrangement_base:on_apply_to()
	for team_id, list in iter(self.Type.TeamMemberLists) do
		self:fill_random(team_id, list)
	end
end

return arrangement_base
