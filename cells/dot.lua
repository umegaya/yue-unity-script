local cell_base = require 'cells.cell_base'
local action_result = require 'common.action_result'
local dot_cell = behavior.new(cell_base)

function cell_base:on_tick_object(obj)
	obj:generate_action_result(action_result.TERRAIN_DAMAGE, self.Type.DamageName, self.Type.DamagePerTick)
end

return dot_cell