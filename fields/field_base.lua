local field_base = behavior.new()

-- base initialization 
function field_base:initialize(data)
	print(data.Objectives, data.Objectives.__IsList__)
	for id in iter(data.Objectives) do
		self.Objectives:Add(id, ObjectivesFactory:Create(id))
	end
	for id in iter(data.Events) do
		self.Events:Add(EventsFactory:Create(id))
	end
	for id in iter(data.Teams) do
		self.Teams:Add(id, TeamsFactory:Create(id))
	end
	self:init_cells(data.Cells)
	self:init_objects(data.Arrangement)
end

-- initialize field cells. unlike normal lua code, cells index is 0 origin. 
function field_base:init_cells(ids)
	self.SizeX = #ids
	self.SizeY = #(ids[1])
	self.Cells = class.new_list(self.SizeY, "CellBase")
	for i=1,self.SizeY do -- y
		local rows = class.new_list(self.SizeX, "CellBase")
		for j=1,self.SizeX do -- x
			rows[j] = CellsFactory:Create(ids[j][i])
			rows[j]:initialize(self)
		end
		self.Cells[i] = rows
	end
end
		
-- find object from id
function field_base:FindObject(id)
	return self.ObjectMap:Get(id)
end

function field_base:new_id()
	self.IdSeed = self.IdSeed + 1
	if self.IdSeed > 2000000000 then
		self.IdSeed = 1
	end
	return self.IdSeed
end

-- get cell. x and y is 0 origin
function field_base:CellAt(x, y)
	if x < self.SizeX and y < self.SizeY and x >= 0 and y >= 0 then
		return self.Cells[x+1][y+1]
	end
end

-- enter logged in user. 
function field_base:login(id, peer, user_data)
	scplog('enter: user_id', id)
	local user = ObjectsFactory:Create("user")
	user.Id = id
	user.Peer = peer
	user.Field = self
	user:initialize(user_data)
	local cell = self:CellAt(user.Team:pop_point(user))
	user:enter_to(cell)
	user:init_event(self)
end
-- exit user when field is finished
function field_base:logout(user)
	scplog('exit: user_id', user.Id)
	user:destroy()
	user:close()
end

-- pop specified object at point x, y
function field_base:pop_at(id, data, x, y)
	local c = self:CellAt(x, y);
	if c then
		return c:pop(id, data);
	end
end

-- prepare objects from data
function field_base:init_objects(arrangement) 
	local ar = ArrangementsFactory:Create(arrangement)
	ar:on_apply_to(self)
end

function field_base:update(dt)
	if self.Finished then
	 	return
	end
	self:do_update(dt)
end
function field_base:invoke(id, cmd)
	local o = self:FindObject(id)
	if not o then
		scplog('object not found', id)
		return 
	end
	return o:invoke_command(cmd)
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
	for ev in iter(self.Events) do
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
			if ServerMode then
				_G.luact.clock.sleep(1.0)
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
function field_base:on_end_field()
end
function field_base:on_exit_user(user, wait)
end
function field_base:on_destroy_field()
end
function field_base:end_field(winner)
	self:on_end_field()
	self:for_all_user(function (user, f)
		local ev = user:reward(f)
		ev.Winner = winner
		ev.ShutdownWait = 15 -- after 15 seconds wait, user will remove from field
		f:on_exit_user(user, ev.ShutdownWait)
		user:end_event(ev) -- show winner and reward and status change to client
	end, self)
	self.Finished = true
	self:on_destroy_field()
end
-- check this field finished or not by checking objective progress
function field_base:check_completion()
	local pglist = {}
	for id, o in iter(self.Objectives) do
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
		p[ot.Id] = o:progress(self)
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
