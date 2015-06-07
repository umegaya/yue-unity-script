require 'common.compat_client' -- compatibility layer for client
-- setup global modules
_G.behavior = require 'common.behavior'
_G.class = require 'common.class'

-- setup local module
local util = require 'common.util'

function InitFixData(game_fix_data)
	if type(game_fix_data) == 'string' then
		game_fix_data = util.decode_json(game_fix_data)
	end
	class.init_fix_data(game_fix_data)
end

function Initialize(field_data)
	if type(field_data) == 'string' then
		field_data = util.decode_json(field_data)
	end
	field = class.new("FieldBase", "fields/field_base.lua")
	field:initialize(field_data)
end

function Enter(user_id, peer, user_data)
	user_data = util.decode_json(user_data)
	local id = field:new_id()
	field:login(id, peer, user_data)
	return id
end

function Update(dt)
	field:update(dt)
end

function SendCommand(id, command)
	if type(command) == 'string' then
		command = util.decode_json(command)
	end
	return field:invoke(id, command)
end
