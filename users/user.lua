local object_base = require 'objects.object_base'
local user = class.new(object_base)

function user:initialize(id, peer, user_data, field)
	self.Peer = peer
	self.Id = id
	self:on_initialize(user_data, field)
end
function user:close()
	if ServerMode then
		-- TODO : do something connection
	else
	end
end
function user:play(ev)
	self.Peer:Play(ev)
end

return user
