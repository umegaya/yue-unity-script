local field_base = class.new()

-- base initialization 
function field_base:initialize(data)
	scplog('initialize: field_data', data)
	for id in iter(data.Objectives) do
		self.Objectives:Add(ObjectiveFactory.Create(id))
	end
	for id in iter(data.Events) do
		self.Events:Add(EventFactory.Create(id))
	end
	for id in iter(data.Teams) do
		self.Teams:Add(id, TeamFactory.Create(id))
	end
	self:InitCells(data.Cells)
	self:init_objects(data.Arrangement)
end

-- enter logged in user. 
function field_base:login(id, peer, user_data)
	scplog('enter: user_id', id)
	local user = ObjectFactory.Create("user")
	user:initialize(id, peer, user_data)
	user:init_event(self)
end
-- exit user when field is finished
function field_base:logout(user)
	scplog('exit: user_id', user.Id)
	self:exit(user)
	user:close()
end
-- enter arbiter object into x, y of field
function field_base:enter(object, x, y)
	local c = self:CellAt(x, y)
	if c then
		--scplog(object, 'enter_to', c)
		object:enter_to(c)
	end
	self.ObjectMap:Add(object.Id, object)
end
-- exit arbiter object from field
function field_base:exit(object)
	local c = self:CellAt(object.X, object.Y);
	if c then
		object:exit_from(c)
	end
	self.ObjectMap:Remove(object.Id)
end


-- pop specified object at point x, y
function field_base:pop_at(id, x, y)
	local c = self:CellAt(x, y);
	if c then
		return c:pop(id);
	end
end

-- prepare objects from data
function field_base:init_objects(arrangement) 
	local ar = ArrangementFactory.Create(arrangement)
	ar:on_apply_to()
end

local cnt = 0
function field_base:update(dt)
	if self.Finished then
	 	return
	end
	self:do_update(dt)
end
function field_base:invoke(id, cmd)
	local o = self:FindObject(id)
	if not o then
		return 
	end
	o:invoke_command(cmd)
end

-- internal system
-- main update routine
function field_base:do_update(dt)
	self:on_tick(dt)
	for x=0,self.SizeX-1 do
		for y=0,self.SizeY-1 do
			self:CellAt(x, y):update(dt)
		end
	end
	local team_id = self:check_completion()
	if team_id then
		self:end_field(team_id)
	end
end	
-- field tick. update team status and event status
function field_base:on_tick(dt)
	for team_id, team in iter(self.Teams) do
		team:on_tick(dt)
	end
	for _, ev in iter(self.Events) do
		ev:on_tick(dt)
	end
end
-- iter over all user in field
function field_base:for_all_user(fn, ...)
	for x=0,self.SizeX-1 do
		for y=0,self.SizeY-1 do
			local r = self:CellAt(x, y):for_all_user(fn, ...)
			if r then
				return r
			end
		end
	end	
end
function field_base:for_all_object(fn, ...)
	for x=0,self.SizeX-1 do
		for y=0,self.SizeY-1 do
			local r = self:CellAt(x, y):for_all_object(fn, ...)
			if r then
				return r
			end
		end
	end	
end
-- calculate rewards, status change after this battle, and notify it to client with winner
-- when field finished.
function field_base:end_field(winner)
	self:for_all_user(function (user)
		local ev = user:reward(self)
		ev.Winner = winner
		user:end_event(ev) -- show winner and reward and status change to client
	end)
	if ServerMode then
		system.queue_destroy(self)
	end
	self.Finished = true
end
-- check this field finished or not by checking objective progress
function field_base:check_completion()
	local pglist = {}
	for o in iter(self.Objectives) do
		local ot = o.Type
		local pg = pglist[ot.AssignedTeam]
		if not pg then
			pg = {}
			pglist[ot.AssignedTeam] = pg
		end 
		local p = pg[ot.Group]
		if not p then
			p = {}
			pg[ot.Group] = p
		end
		p[ot.Id] = o:progress()
	end
	for team_id, team_state in iter(pglist) do
		-- scplog('team', team_id)
		local finished = false
		for group,gstate in iter(team_state) do
			for id, progress in iter(gstate) do
				-- scplog('progress', id, progress)
				if progress == 100 then -- progress == 100(%), means finished
					finished = true
					goto on_finished
				end
			end
		end
::on_finished::
		if finished then
			return team_id
		end
	end	
	-- not finished. send each user to progress
	self:for_all_user(function (user)
		user:progress_event(pglist[user.Team.Type.Id])
	end)
end

function field_base:random_cell()
	local rx, ry = math.random(0, self.SizeX-1), math.random(0, self.SizeY-1)
	return self:CellAt(rx, ry)
end

return field_base
