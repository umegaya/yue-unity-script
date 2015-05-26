local action_result = behavior.new()

table.merge(action_result, {
	DAMAGE = 1,
	HEAL = 2,
	EFFECT = 3, -- buff/debuff
	IMMUTE = 4,
	DODGE = 5,
	TERRAIN_DAMAGE = 6,
	TERRAIN_HEAL = 7,
})

function action_result:initialize(tp, name, ...)
	self.Type = tp
	self.Name = name
	for _, v in ipairs({...}) do
		self.Args:Add(v)
	end
end

function action_result:new_empty_combo_result()
	local ar = class.new("ActionResult", "common/action_result.lua")
	ar.Type = self.Type
	for v in iter(self.Args) do
		ar.Args:Add(v)
	end
	return ar
end

function action_result:invoke(target)
	local dead = target.IsDead
	--scplog('invoke', dead, self.Type)
	if self.DAMAGE == self.Type then
		target:add_damage(self:int_arg(3))
	elseif self.HEAL == self.Type then
		target:add_heal(self:int_arg(3))
	elseif self.EFFECT == self.Type then
		target:add_effect(self:skill_arg(2))
	elseif self.TERRAIN_DAMAGE == self.Type then
		target:add_damage(self:int_arg(1))
	elseif self.TERRAIN_HEAL == self.Type then
		target:add_heal(self:int_arg(1))
	elseif self:is_invalid() then
	end
	target:action_event(target, self)
	if (not dead) and target.IsDead then
		target:dead_event(target)
	end
end

function action_result:apply_combo(num_combo, ar)
	if self.DAMAGE == self.Type then
		self:set_arg(3, math.ceil(1.1 * (ar:int_arg(3) + self:int_arg(3))))
	elseif self.HEAL == self.Type then
		self:set_arg(3, math.ceil(1.1 * (ar:int_arg(3) + self:int_arg(3))))
	elseif self.EFFECT == self.Type then
		self.Skill.Duration = math.ceil(self.Skill.Duration * 1.1);
	elseif self:is_invalid() then
	else
	end
end

function action_result:add_combo_data(combo)
	for ar in iter(combo) do
		self.ComboData:Add(ar)
	end
end

function action_result:has_invoker()
	local t = self.Type
	return t == self.DAMAGE or t == self.HEAL or t == self.EFFECT
end
function action_result:can_start_combo()
	if self:has_invoker() then
		local skill = self:skill_arg(2)
		return skill.Type.Group ~= nil
	end
end
function action_result:can_combo_with(result)
	if self:can_start_combo() and result:has_invoker() then
		local skill = self:skill_arg(2)
		local result_skill = result:skill_arg(2)
		for group in iter(skill.Type.AcceptGroups) do
			if group == result_skill.Type.Group then
				return true
			end
		end	
	end
end

function action_result:is_invalid()
	return self.IMMUTE == self.Type or self.DODGE == self.Type
end
function action_result:int_arg(idx)
	return self.Args[idx]
end
function action_result:str_arg(idx)
	return self.Args[idx]
end
function action_result:skill_arg(idx)
	return self.Args[idx]
end
function action_result:object_arg(idx)
	return self.Args[idx]
end
function action_result:set_arg(idx, v)
	self.Args[idx] = v
end

function action_result:display_data(recurse)
	local r = {
		Type = self.Type,
		Name = self.Name,
	}
	if self.DAMAGE == self.Type then
		r.AttackerId = self:object_arg(1).Id
		r.Damage = self:int_arg(3)

	elseif self.TERRAIN_DAMAGE == self.Type then
		r.Damage = self:int_arg(1)

	elseif self.HEAL == self.Type then
		r.AttackerId = self:object_arg(1).Id
		r.Heal = self:int_arg(3)

	elseif self.TERRAIN_HEAL == self.Type then
		r.Heal = self:int_arg(1)

	elseif self.EFFECT == self.Type then
		r.AttackerId = self:object_arg(1).Id
		r.Skill = self:skill_arg(2):display_data()
		
	elseif self:is_invalid() then
	end
	if self.ComboData and self.ComboData:Size() > 0 then
		if recurse then
			scplog('element of combodata should not have combodata')
			error('err')
			return
		end
		local ComboData = {}
		for ar in iter(self.ComboData) do
			table.insert(ComboData, ar:display_data(true))
		end
		r.ComboData = ComboData
	end
	return r
end

return action_result
