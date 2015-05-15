local character = require 'objects.character'
local hero = class.new(character)

function hero:on_initialize(data)
	self.OwnerId = data.OwnerId
	self.Team = GetField().Teams[data.TeamId]
	self.Team:join(self)
	self:init_data_by_type()
	-- hero enter into field with owner, so does not enter by itself.
end

function hero:init_data_by_type()
	character.init_data_by_type(self)
end

function hero:display_data()
	return character.display_data(self)
end

return hero
