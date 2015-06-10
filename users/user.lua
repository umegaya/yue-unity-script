local object_base = require 'objects.object_base'
local user = behavior.new(object_base)

function user:join_team(team_id)
	self.Team = self.Field.Teams[team_id]
	self.Team:join_user(self)
end
function user:leave_team()
	self.Team:leave_user(self)
end
function user:close()
	if ServerMode then
		luact.close_peer(self.Peer)
	end
end

return user
