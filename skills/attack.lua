local skill_base = require 'skills.skill_base'
local action_result = require 'common.action_result'
local attack = class.new(skill_base)

function attack:add_bonus_damage(base_damage)
	if self.Type.BonusType == "add" then
		return base_damage + self.Type.Bonus
	elseif self.Type.BonusType == "multiply" then
		return base_damage * self.Type.Bonus
	end
end

function attack:on_use(user, target)
	local d = self:add_bonus_damage(user:get_attack_damanage(target))
	target:generate_skill_result(action_result.DAMAGE, user, self, d)
end

return attack
