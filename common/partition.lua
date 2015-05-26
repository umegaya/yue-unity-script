local partition = behavior.new()

partition.MAX_USER = 5

function partition:Enter(o)
	self:CommonEnter(self.Teams, o)
end
function partition:EnterUser(u)
	self:CommonEnter(self.Users, u)
end
function partition:IsUserFull()
	local cnt = 0
	for k,v in iter(self.Users) do
		cnt = cnt + v:Size()
	end
	return cnt >= paritition.MAX_USER
end
function partition:CommonEnter(d, o)
	local team_id = o.Team.Type.Id
	local list = d:Get(team_id)
	if not list then
		list = class.new_list()
		d:Add(team_id, list)
	end
	list:Add(o)
	--for k,v in iter(self.Teams) do
	--	scplog("list:" + k + "|" + v);
	--end
	o.Partition = self
end

function partition:Exit(o)
	self:CommonExit(self.Teams, o)
end
function partition:ExitUser(u)
	self:CommonExit(self.Users, u)
end
function partition:CommonExit(d, o)
	local team_id = o.Team.Type.Id
	local list = d:Get(team_id)
	if list then
		list:Remove(o)
		o.Partition = nil
		return list:Size() <= 0
	end
	return false
end

return partition
