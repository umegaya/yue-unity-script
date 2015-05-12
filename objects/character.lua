local object_base = require 'objects.object_base'
local character = class.new(object_base)

function character:on_initialize(data, field)
	return object_base.on_initialize(self, data, field)
end

return character