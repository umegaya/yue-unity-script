local field_base = require 'fields.field_base'
local sweeper = require 'engine.user_sweeper'

function field_base:on_end_field()
	self.sweeper = sweeper.new()
end
function field_base:on_exit_user(user, wait)
	self.sweeper:add_user(user, wait)
end
function field_base:on_destroy_field()
	self.sweeper:start(self)
end

return field_base
