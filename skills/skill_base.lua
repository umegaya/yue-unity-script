local skill_base = class.new()


function skill_base:display_data()
	return {
		Name = self.Type.Name,
		Id = self.Type.Id,
		Range = self.Type.Range,
		Scope = self.Type.Scope,
		Duration = self.Type.Duration,
	}
end

function skill_base:effective(user, target)
	local scope = self.Type.Scope
	if scope == "all" then
		return true
	elseif scope == "same_team" then
		return user.Team.Type == target.Team.Type
	elseif scope == "other_team" then
		return user.Team.Type ~= target.Team.Type
	elseif scope == "friendly" then
		return user:friendly(target)
	elseif scope == "hostile" then
		return user:hostile(target)
	end
end
 
function skill_base:get_target(user, range)
	if target == "single" then
		return user:get_skill_target(self)
	elseif target == "parition" then
		return user.Paritition
	elseif target == "cell" then
		return user:current_cell()
	elseif target == "field" then
		return GetField()
	end
end

function skill_base:use(user, target)
	local range = skill.Type.Range
	if not target then
		target = self:get_target(user, range)
	end
	if range == "single" then
		-- target == ObjectBase
		if self:effective(user, target) then
			self:on_use(user, target)
		end
	elseif range == "partition" then
		-- target == Partition
		target:for_all_object_in_partition(function (obj, u, sk)
			if self:effective(u, obj) then
				sk:on_use(u, obj)
			end
		end, user, skill)
	else
		-- target == CellBase
		-- target == FieldBase
		target:for_all_object(function (obj, u, sk)
			if self:effective(u, obj) then
				sk:on_use(u, obj)
			end
		end, user, skill)
	end
end

-- callback: should override in child
function skill_base:on_use(user, target)
	if self.Type.Duration > 0 then
		target:generate_action_result(action_result.EFFECT, user, self)
	end
end
function skill_base:on_tick(target)
end
function skill_base:on_effect_added(target, effect)
end

return skill_base
