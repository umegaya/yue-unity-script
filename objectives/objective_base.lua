local objective_base = behavior.new()

function objective_base:progress()
	return 0
end

function objective_base:display_data(field)
	return {
		Id = self.Type.Id,
		Name = self.Type.Name,
		Progress = self:progress(field),
	}
end

return objective_base