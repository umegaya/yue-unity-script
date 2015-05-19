local objective_base = require 'objectives.objective_base'
local loss_ratio = class.new(objective_base)

function loss_ratio:progress()
	local team = GetField():GetTeam(self.Type.TeamId)
	local count = team:count_object()
	if count <= 0 then
		return 0
	end
	return math.min(100, math.ceil((100 * (count - team:count_alive_object())) / count))
end

return loss_ratio
