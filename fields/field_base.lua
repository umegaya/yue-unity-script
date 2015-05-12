local field_base = class.new()
function field_base:initialize(data)
	scplog('initialize: field_data', field_data)
	for id in iter(data) do
		self.Objectives:Add(ObjectiveFactory.Create(id))
	end
end
function field_base:enter(id, peer, user_data)
	scplog('enter: user_data', user_data)
	peer:Play("start play event")
end
local current = Time.time
function field_base:update(dt)
	if (Time.time - current) > 1 then
		scplog('tick')
		current = Time.time
	end
end
function field_base:invoke(cmd)
	scplog('command', command)
end

return field_base
