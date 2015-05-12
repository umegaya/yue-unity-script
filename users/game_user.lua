local user = require 'users.user'
local game_user = class.new(user)

function game_user:on_initialize(user_data, field)
	for data in iter(user_data.Heroes) do
		local hero = ObjectFactory.Create(data.Id)
		data.TeamId = user_data.TeamId
		hero:initialize(data, field)
		self.Heroes:Add(hero)
	end
	self.Objective = field.Objectives[user_data.ObjectiveId]
	user.on_initialize(self, user_data, field)
end

function game_user:enter_to(cell)
	local p = cell:get_vacant_partition(self, true);
	scplog("enter_to", p)
	if p then
		p:EnterUser(self);
		for h in iter(self.Heroes) do
			p:Enter(h)
		end
	end
end

function game_user:exit_from(cell)
	local p = self.Partition
	scplog("exit_from", p)
	p:ExitUser(self)
	for h in iter(self.Heroes) do
		p:Exit(h)
	end	
end

function game_user:reward(field)
	-- TODO : add reward data to field, and compute actual reward 
end

return game_user
