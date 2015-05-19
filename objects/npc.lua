local character = require 'objects.character'
local npc = class.new(character, require 'mixin.cooldown')

function npc:display_data()
	return character.display_data(self)
end

function npc:do_action(target)
	-- TODO : execute action which is decided by AI
	local idx = math.random(0, self.Skills.Count - 1)
	local skill = self.Skills[idx]
	skill:use(self, target)
end

return npc
