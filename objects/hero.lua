local character = require 'objects.character'
local hero = class.new(character)

function hero:on_initialize(data, field)
	self.Team = field.Teams[data.TeamId]
	-- hero enter into field with owner, so does not enter by itself.
end

return hero
