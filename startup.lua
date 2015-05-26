-- TODO : this is time-eater? if so, we need to reuse single lua env.
if import then
	require 'common.compat_client' -- compatibility layer for client
else
	_G.ServerMode = true
	require 'common.compat_server' -- compatibility layer for server
end
-- setup global modules
_G.behavior = require 'common.behavior'
_G.class = require 'common.class'
-- setup local module
local util = require 'common.util'

local field
function GetField()
	return field
end

function InitFixData(game_fix_data)
	class.load_all_decls()
	game_fix_data = util.decode_json(game_fix_data)
	class.init_fix_data(game_fix_data)
end

function Initialize(f, field_data)
	field = class.new("FieldBase", "fields/field_base.lua")
	field_data = util.decode_json(field_data)
	field:initialize(field_data)
end

function Enter(otp, peer, user_data)
	user_data = util.decode_json(user_data)
	if ServerMode then
		error("TODO : get id and user_data from otp")
	else
		local id = field:new_id()
		field:login(id, peer, user_data)
		return id
	end
end

function Update(dt)
	field:update(dt)
end

function SendCommand(id, command)
	command = util.decode_json(command)
	return field:invoke(id, command)
end
