local cell_base = require 'cells.cell_base'
local dot_cell = class.new(cell_base)

function cell_base:on_tick_object(obj)
	obj.Hp = obj.Hp - self.Type.DamagePerTick
end

return dot_cell