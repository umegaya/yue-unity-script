local object_base = require 'objects.object_base'
local user = class.new(object_base)

function user:initialize(id, peer, user_data)
	self.Peer = peer
	self.Id = id
	object_base.initialize(self, user_data)
end
function object_base:destroy()
	self.Team:leave_user(self)
	GetField():logout(self)
end
function user:join_team(team_id)
	self.Team = GetField().Teams[team_id]
	self.Team:join_user(self)
end
function user:leave_team()
	self.Team:leave_user(self)
end
function user:close()
	if ServerMode then
		-- TODO : do something connection
	else
	end
end

return user
