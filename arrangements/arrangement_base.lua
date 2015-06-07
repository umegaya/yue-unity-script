local arrangement_base = behavior.new()

function arrangement_base:fill_random(field, team_id, candidates)
	for id in iter(candidates) do
		local g = GroupsFactory:Create(id)
		local cell = field:random_cell()
		g:on_apply_to(cell, team_id)
	end
end

function arrangement_base:on_apply_to(field)
	for team_id, list in iter(self.Type.TeamMemberLists) do
		self:fill_random(field, team_id, list)
	end
end

return arrangement_base
