local user = require 'users.user'
local game_user = class.new(user)

function game_user:on_initialize(user_data)
	for data in iter(user_data.Heroes) do
		local hero = ObjectFactory.Create(data.Id)
		data.TeamId = user_data.TeamId
		data.OwnerId = user.Id
		hero:initialize(data, field)
		self.Heroes:Add(hero)
	end
	self.Objective = GetField().Objectives[user_data.ObjectiveId]
	user.on_initialize(self, user_data)
end

function game_user:enter_to(cell)
	local p = cell:get_vacant_partition(self, true);
	if p then
		p:EnterUser(self);
		for h in iter(self.Heroes) do
			p:Enter(h)
		end
	end
end

function game_user:exit_from(cell)
	local p = self.Partition
	p:ExitUser(self)
	for h in iter(self.Heroes) do
		p:Exit(h)
	end	
end

function game_user:reward()
	-- TODO : add reward data to field, and compute actual reward 
	return {}
end

-- field event to renderer
function game_user:build_scene_payload()
	local cell = GetField():CellAt(self.X, self.Y)
	local teams, terrain = {}, cell:display_data()
	local p = self.Partition
	for team_id, team in iter(p.Teams) do
		local data = {}
		for obj in iter(team) do
			table.insert(data, obj:display_data())	
		end
		teams[team_id] = data
	end
	return { 
		Teams = teams, Terrain = terrain, 
		Objective = self.Objective:display_data(), 
		TeamStatus = self.Team:display_data() 
	}
end
function game_user:init_event()
	return self.Peer:Play("init", self:build_scene_payload())
end
function game_user:end_event(payload)
	return self.Peer:Play("end", payload)
end
function game_user:progress_event(payload)
	return self.Peer:Play("progress", payload)
end

return game_user
