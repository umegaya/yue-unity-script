-- TODO : this is time-eater? if so, we need to reuse single lua env.
if import then
	require 'common.compat_client' -- compatibility layer for client
else
	_G.ServerMode = true
	require 'common.compat_server' -- compatibility layer for server
end
-- setup global modules
_G.class = require 'common.class'


local field
function Initialize(f, field_data)
	field = ObjectWrapper.Wrap(f, "fields/field_base.lua");
	field:initialize(field_data)
	field_update = field.update
end

function Enter(id, peer, user_data)
	field:login(id, peer, user_data)
end

function Update(dt)
	field:update(dt)
end

function SendCommand(command)
	field:invoke(command)
end

