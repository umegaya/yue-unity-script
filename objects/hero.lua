local character = require 'objects.character'
local hero = class.new(character)

function hero:initialize(data)
	self.OwnerId = data.OwnerId
	self.Team = GetField().Teams[data.TeamId]
	self.Team:join(self)
    -- TODO : should apply this character's growth (level or exp?)
	-- Growth factor should added to HeroObjectType
  	self.MaxHp = self.Type.MaxHp
  	self.Hp = self.MaxHp
    self.Attack = self.Type.Attack
    self.Defense = self.Type.Defense
	-- TODO : apply equipped skill, not use data from characertypebase.
	-- (after that, Type.Skills should move to NPCObjectTypes)
  	for skill_id in iter(self.Type.Skills) do
		self.Skills:Add(SkillFactory.Create(skill_id))
  	end
end
function hero:initial_pop()
	-- hero enter into field with owner, so does not enter by itself.
end

function hero:display_data()
	return character.display_data(self)
end

function hero:get_owner()
	return self:current_cell():FindObject(self.OwnerId)
end

-- event to hero will be transferred to its owner (user)
function hero:action_event(target, action_result)
	return self:get_owner():action_event(target, action_result)
end
function hero:dead_event(target)
	return self:get_owner():dead_event(target)
end
function hero:status_change_event(target)
	return self:get_owner():status_change_event(target)
end

return hero
