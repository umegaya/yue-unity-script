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
    self.MaxWp = self.Type.MaxWp
    self.Wp = self.MaxWp
    self.Attack = self.Type.Attack
    self.Defense = self.Type.Defense
	-- TODO : apply equipped skill, not use data from characertypebase.
	-- (after that, Type.Skills should move to NPCObjectTypes)
  	for skill_id in iter(self.Type.Skills) do
		self.Skills:Add(SkillFactory.Create(skill_id))
  	end
	-- hero enter into field with owner, so does not enter by itself, only added to objectmap
	GetField().ObjectMap:Add(self.Id, self)
end
function hero:initial_pop()
end

function hero:display_data()
	local d = character.display_data(self)
	d.OwnerId = self.OwnerId
	return d
end

function hero:get_owner()
	return GetField():FindObject(self.OwnerId)
end

return hero
