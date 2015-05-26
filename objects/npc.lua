local character = require 'objects.character'
local npc = behavior.new(character, require 'mixin.cooldown')

function npc:display_data()
	return character.display_data(self)
end

function npc:do_action(target)
	-- TODO : execute action which is decided by AI
	local skill = self.Skills:GetRandom()
	skill:use(self, target)
end

return npc
