local object_base = require 'objects.object_base'
local util = require 'common.util'
local action_result = require 'common.action_result'
local character = class.new(object_base)

function character:initialize(data)
  	self.MaxHp = self.Type.MaxHp
  	self.Hp = self.MaxHp
    self.MaxWp = self.Type.MaxWp
    self.Wp = self.MaxWp
    self.Attack = self.Type.Attack
    self.Defense = self.Type.Defense
  	for skill_id in iter(self.Type.Skills) do
		self.Skills:Add(SkillFactory.Create(skill_id))
  	end
    return object_base.initialize(self, data)
end

function character:update(dt)
    self:resolve_queue()
    object_base.update(self, dt)
end

function character:action_event(target, action_result)
end
function character:dead_event(target)
end
function character:status_change_event(target)
end

function character:new_action_result(result_id, name, ...)
    local ar = ActionResultFactory.Create(result_id, name, ...)
    return ObjectWrapper.Wrap(ar, "common/action_result.lua")
end
function character:generate_skill_result(result_id, doer, skill, ...)
    local ar = self:new_action_result(result_id, skill.Type.Name, doer, skill, ...)
    ar = self:apply_effect_to_result(ar) -- apply buff to this battle effect. decrease or immute damage, etc ...
    self.ActionQueue:Add(ar)
end
function character:generate_action_result(result_id, ...)
    local ar = self:new_action_result(result_id, doer, skill, ...)
    ar = self:apply_effect_to_result(ar) -- apply buff to this battle effect. decrease or immute damage, etc ...
    self.ActionQueue:Add(ar)
end

-- choose skill target. currently random. npc will override this to more clever selection
function character:get_skill_target(skill)
	local targets = {}
	self.Partition:for_all_object_in_partition(function (obj, u, list)
		if self:effective(u, obj) then
			table.insert(list, obj)
		end
	end, self, skill, targets)
	local idx = math.random(1, #targets)
	return targets[idx]
end

function character:get_attack_damanage(target)
    return Math.Max(self.Attack - target.Defence, 1)
end

function character:get_skill_by_id(skill_id)
    for skill in iter(self.Skills) do
        if skill.Id == skill_id then
            return skill
        end
    end
end

function character:apply_effect_to_result(ar)
    for e in iter(self.Effects) do
        ar = e:on_effect_added(self, ar)
        if ar:is_invalid() then -- immute, dodge
            break
        end
    end
    return ar
end

function character:add_effect(skill)
    local cloned = skill:Clone()
    cloned.Duration = cloned.Type.Duration
    self.Effects:Add(cloned)
    self:status_change_event(self)
end

function character:add_damage(d)
    self.Hp = self.Hp + d
    self.Hp = Math.Max(0, Math.Min(self.MaxHp, self.Hp))
    self:status_change_event(self)
end

function character:resolve_queue()
    -- search coordination chain upto possible longest length
    local now = util.now()
    if (now - self.LastUpdateQueue) > 1.0 then
        if self.ComboChain.Count > 0 then
            self:invoke_combo()
        end
    end
    for ar in iter(self.ActionQueue) do
        local processed
        if self.ComboChain.Count > 0 then
            local last = self:LastComboResult()
            if ar:can_combo_with(last) then
                self.ComboChain:Add(ar)
                self.LastUpdateQueue = now
                processed = true
            else
                self:invoke_combo()
            end
        end
        if not processed then
            if ar:can_start_combo() then
                self.ComboChain:Add(ar)
                self.LastUpdateQueue = now
            else
                ar:invoke(self)
            end
        end
    end
    self.ActionQueue:Clear()
end

function character:invoke_combo()
    local name -- chain name like 二段二段二段二段斬り
    local root_ar
    local participants = {}
    if self.ComboChain.Count <= 1 then
        self:LastComboResult():invoke(self)
        return
    end
    for ar in iter(self.ComboChain) do
        local skill = ar:skill_arg(1)
        if not name then
            root_ar = ar
            name = skill.Prefix
        elseif i < #chain then
            name = name .. skill.PreFix
            root_ar:apply_combo(i, ar)
        else
            name = name .. skill.PostFix
            root_ar:apply_combo(i, ar)
        end
    end
    root_ar:add_combo_data(chain)
    root_ar.Name = name
    root_ar:invoke(self)
    self.ComboChain:Clear()
end

function character:status_display_data()
  	local skills, effects = {}, {}
  	for skill in iter(self.Skills) do
    	table.insert(skills, skill:display_data())
  	end
  	for effect in iter(self.Effects) do
    	table.insert(effects, effect:display_data())
  	end
  	return {
		TargetId = self.Id, -- using this for making some action
		MaxHp = self.MaxHp,
		Hp = self.Hp,
		Skills = skills,
        Effects = effects,
  	}
end

function character:display_data()
  	local skills, effects = {}, {}
  	for skill in iter(self.Skills) do
    	table.insert(skills, skill:display_data())
  	end
  	for effect in iter(self.Effects) do
    	table.insert(effects, effect:display_data())
  	end
  	return {
		TargetId = self.Id, -- using this for making some action
		Id = self.Type.Id,
		Display = self.Type.DisplayPosition, -- user or enemy
		Name = self.Type.Name,
		OwnerId = self.OwnerId,
		TeamId = self.Team.Id,
		MaxHp = self.MaxHp,
		Hp = self.Hp,
        MaxWp = self.MaxWp,
        Wp = self.Wp,
		Skills = skills,
        Effects = effects,
  	}
end

return character
