local objective_base = class.new()

function objective_base:progress()
	return 0
end

function objective_base:display_data()
	return {
		Id = self.Type.Id,
		Name = self.Type.Name,
		Progress = self:progress(),
	}
end

return objective_base