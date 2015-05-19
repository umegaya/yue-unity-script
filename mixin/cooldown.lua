local cooldown = class.new()

function cooldown:init_cooldown()
	self.Cooldown = self.Type.WaitSec
end
function cooldown:cooldown(dt)
	if not dt then
		scplog('dt null')
	end
	if self.Cooldown <= 0 then
		return false
	end
	self.Cooldown = self.Cooldown - dt
	if self.Cooldown <= 0 then
		self.Cooldown = 0
		return true
	end
	return false
end
function cooldown:set_cooldown(time)
	self.Cooldown = time or self.Type.WaitSec
end

return cooldown
