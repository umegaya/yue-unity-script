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
function character:do_action()
    -- default do nothing
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
    local ar = self:new_action_result(result_id, ...)
    ar = self:apply_effect_to_result(ar) -- apply buff to this battle effect. decrease or immute damage, etc ...
    self.ActionQueue:Add(ar)
end

-- choose skill target. currently random. npc will override this to more clever selection
function character:get_skill_target(skill)
	return self:choose_random_visible_object(function (obj, list, u, skill)
        --scplog('get_skil_target', obj.Type.Id, u.Type.Id, skill)
		if skill:effective(u, obj) then
			table.insert(list, obj)
		end
	end, self, skill)
end

function character:get_attack_damanage(target)
    return math.max(self.Attack - target.Defense, 1)
end

function character:get_skill_by_id(skill_id)
    for skill in iter(self.Skills) do
        if skill.Type.Id == skill_id then
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

function character:add_effect(skill, notice)
    local cloned = skill:Clone()
    cloned.Duration = cloned.Type.Duration
    self.Effects:Add(cloned)
    if notice then
        self:status_change_event(self)
    end
end

-- hp/wp
function character:add_damage(d, notice)
    self.Hp = self.Hp - d
    self.Hp = math.max(0, math.min(self.MaxHp, self.Hp))
    if notice then
        self:status_change_event(self)
    end
end
function character:add_heal(h, notice)
    self:add_damege(-h, notice)
end
function character:add_wp(wp)
    self.Wp = self.Wp + wp
    self.Wp = math.max(0, math.min(self.MaxWp, self.Wp))
    self:status_change_event(self)    
end
function character:consume_wp(wp)
    self:add_wp(-wp)
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
            local last = self:LastComboAction()
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
        self:LastComboAction():invoke(self)
        self.ComboChain:Clear()
        return
    end
    local i, max = 1, self.ComboChain.Count
    for ar in iter(self.ComboChain) do
        local skill = ar:skill_arg(1)
        local type = skill.Type
        if not name then
            root_ar = ar:Clone()
            name = type.Prefix
        elseif i < max then
            name = name .. type.Prefix
            root_ar:apply_combo(i, ar)
        else
            name = name .. type.Postfix
            root_ar:apply_combo(i, ar)
        end
        i = i + 1
    end
    root_ar:add_combo_data(self.ComboChain)
    root_ar.Name = name
    root_ar:invoke(self)
    self.ComboChain:Clear()
end

function character:status_display_data()
  	local effects = {}
  	for effect in iter(self.Effects) do
    	table.insert(effects, effect:display_data())
  	end
  	return {
		TargetId = self.Id, -- using this for making some action
		MaxHp = self.MaxHp,
		Hp = self.Hp,
		MaxWp = self.MaxWp,
        Wp = self.Wp,
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
