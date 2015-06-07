local util = behavior.new()
local json = require 'common.dkjson'

if _G.ServerMode then
local luact = require 'luact.init'
function util.now()
	return luact.clock.get()
end
else
function util.now()
	return Time.time
end
end

function util.decode_json(jsonstr)
	-- scplog('decode_json start', jsonstr)
	return json.decode(jsonstr, 1, nil, class.dict_mt, class.list_mt)
end

return util