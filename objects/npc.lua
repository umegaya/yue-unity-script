local character = require 'objects.character'
local npc = class.new(character)

function npc:init_data_by_type()
	character.init_data_by_type(self)
end

function npc:display_data()
	return character.display_data(self)
end

return npc
