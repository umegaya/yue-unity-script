local user = require 'users.user'
local game_user = class.new(user)

function game_user:initialize(id, peer, user_data)
	for data in iter(user_data.Heroes) do
		local hero = ObjectFactory.Create(data.Id)
		data.TeamId = user_data.TeamId
		data.OwnerId = id -- id will be owner 
		hero:initialize(data, field)
		self.Heroes:Add(hero)
	end
	self.Objective = GetField().Objectives[user_data.ObjectiveId]
	user.initialize(self, id, peer, user_data)
end

function game_user:battle(orders)
	for order_target_id, order in iter(orders) do
		local o = GetField():FindObject(order_target_id)
		if not o then
			scplog("order target not exist", order_target_id)
			break
		end
		if o.IsDead then
			scplog("order target dead", o.Id)
			break
		end
		if o.OwnerId ~= self.Id then
			scplog("different owner", o.OwnerId, self.Id)
			break
		end
		local skill = o:get_skill_by_id(order.SkillId)
		if not skill then
			scplog("skill not equipped", order.SkillId)
			break
		end
		if skill.Type.Wp > o.Wp then
			scplog("no wp", skill.Type.Wp, o.Wp)
			break
		end
		local target = order.TargetId and GetField():FindObject(order.TargetId)
		skill:use(o, target)
	end
end

function game_user:invoke_command(cmd)
	if cmd.Type == "battle" then
		self:battle(cmd.Orders)
	elseif cmd.Type == "move" then
		self:move(cmd.X, cmd.Y)
	end
end

function game_user:enter_to(cell)
	local p = cell:get_vacant_partition(self, true);
	if p then
		for h in iter(self.Heroes) do
			h:enter_to(cell, p)
		end
		p:EnterUser(self);
	end
end

function game_user:exit_from(cell)
	local p = self.Partition
	p:ExitUser(self)
	for h in iter(self.Heroes) do
		h:exit_from(cell)
	end	
end

function game_user:reward()
	-- TODO : add reward data to field, and compute actual reward 
	return {}
end

-- field event to renderer
function game_user:build_scene_payload()
	local cell = GetField():CellAt(self.X, self.Y)
	local user_side, enemy_side, terrain = {}, {}, cell:display_data()
	local p = self.Partition
	for team_id, team in iter(p.Teams) do
		local data = {}
		for obj in iter(team) do
			table.insert(data, obj:display_data())	
		end
		user_side[team_id] = data
	end
	for team_id, team in iter(cell.EnemySide.Teams) do
		local data = {}
		for obj in iter(team) do
			table.insert(data, obj:display_data())	
		end
		enemy_side[team_id] = data
	end
	return { 
		UserSide = user_side, EnemySide = enemy_side,
		Terrain = terrain, 
		X = self.X, Y = self.Y,
		Objective = self.Objective:display_data(), 
		TeamStatus = self.Team:display_data() 
	}
end
function game_user:build_action_payload(target, action_result)
	return {
		TargetId = target and target.Id,
		Action = action_result:display_data(),
	}
end
function game_user:play_event(type, payload)
	if not _G.ServerMode then
		return self.Peer:Play(type, payload)
	else
		-- TODO : server mode notification
	end
end
function game_user:action_event(invoker, action_result)
	return self:play_event("action", self:build_action_payload(invoker, action_result))
end
function game_user:dead_event(target)
	return self:play_event("dead", { TargetId = target.Id })
end
function game_user:enter_event(target)
	return self:play_event("enter", target:display_data())
end
function game_user:exit_event(target)
	return self:play_event("exit", { TargetId = target.Id })
end
function game_user:status_change_event(target)
	return self:play_event("status_change", target:status_display_data())
end
function game_user:init_event()
	return self:play_event("init", self:build_scene_payload())
end
function game_user:end_event(payload)
	return self:play_event("end", payload)
end
function game_user:progress_event(payload)
	return self:play_event("progress", payload)
end

return game_user
