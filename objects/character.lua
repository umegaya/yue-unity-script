local object_base = require 'objects.object_base'
local character = class.new(object_base)

function character:on_initialize()
	self:init_data_by_type()
	return object_base.on_initialize(self)
end

function character:init_data_by_type()
	self.MaxHp = self.Type.MaxHp
	self.Hp = self.MaxHp
end

function character:display_data()
	return {
		TargetId = self.Id, -- using this for making some action
		Id = self.Type.Id,
		Name = self.Type.Name,
		OwnerId = self.OwnerId,
		TeamId = self.Team.Id,
		MaxHp = self.MaxHp,
		Hp = self.Hp,
	}
end

return character
