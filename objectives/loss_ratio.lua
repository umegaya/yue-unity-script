local objective_base = require 'objectives.objective_base'
local loss_ratio = class.new(objective_base)

function loss_ratio:progress(field)
	local team = field:GetTeam(self.Type.TeamId)
	if team.TotalPopCount <= 0 then
		return 0
	end
	return math.min(100, math.ceil((100 * team:count_alive_object()) / team.TotalPopCount))
end

return loss_ratio
