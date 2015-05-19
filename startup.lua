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
function GetField()
	return field
end

function Initialize(f, field_data)
	field = ObjectWrapper.Wrap(f, "fields/field_base.lua");
	field:initialize(field_data)
end

function Enter(id, peer, user_data)
	field:login(id, peer, user_data)
end

function Update(dt)
	field:update(dt)
end

function SendCommand(id, x, y, command)
	field:invoke(id, x, y, command)
end

