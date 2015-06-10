local _M = {}
local ffi
local vaults = {}
local metaclass = {}
local class_and_index_map = {}
local collection_type_info = {}


local LIST_TYPE_MATCHER = '^List%s*<'
local LIST_TYPE_PARAM_INJECTOR = '^List%s*<%s*([%w<>]+)%s*>'
local DICT_TYPE_MATCHER = '^Dictionary%s*<'
local DICT_TYPE_PARAM_INJECTOR = '^Dictionary%s*<%s*([%w<>]+)%s*,%s*([%w<>]+)%s*>'


-- type check based on class declaration
local function typecheck(t, v)	
	local vt = type(v)
	if vt ~= "cdata" then
		if t == "int" or t == "double" or t == "float" then
			if vt ~= 'number' then 
				return "data error: number required but:"..vt
			end
		elseif t == "string" then
			if vt ~= 'string' then 
				return "data error: string required but:"..vt
			end
		elseif t == "bool" then
			if vt ~= 'boolean' then
				return "data error: boolean required but:"..vt
			end
		elseif t == "object" then
			if ffi then
				return "data error: cdata required but:"..vt
			elseif vt ~= "userdata" then
				return "data error: userdata required but:"..vt
			end
		elseif t:match(LIST_TYPE_MATCHER) then
			if vt ~= 'table' or (not v.__IsList__) then
				return "data error: list required but:"..vt.."|"..tostring(v.__IsList__)
			end
		elseif t:match(DICT_TYPE_MATCHER) then
			if vt ~= 'table' or (not v.__IsDict__) then
				return "data error: dict required but:"..vt.."|"..tostring(v.__IsDict__)
			end
		else
			local mt = metaclass[t]
			if mt then
				if vt ~= "table" or (not v.__class__) then
					return "data error: child class of ["..mt.name.."] required but:"..vt.."|"..tostring(v.__class__)
				elseif not v.__class__:derived_by(mt.name) then
					return "data error: child class of ["..mt.name.."] required but:"..v.__class__.name
				end
			else
				return "invalid assignment:["..k.."] expects ["..t.."] but ["..vt.."] given"
			end
		end	
	else
		-- because luajit autometically checks type compatibility for cdata
		assert(ffi)
	end
end

local function typecheck_and_report(t, v)
	if t then
		local msg = typecheck(t, v)
		if msg then
			scplog(msg)
			error(msg)
		end
	end
end



-- default variables
local empty_string = "" -- string default
-- collections
local list_mt, dict_mt = { __IsList__ = true }, {  __IsDict__ = true }
local new_list, new_dict
local memory, array, hash, _string 
list_mt.__index = list_mt
if DEBUG then
	function list_mt:Add(elem)
		local i = collection_type_info[self]
		typecheck_and_report(i.__valtype__, v)
		table.insert(self, elem)
	end
	function list_mt:__gc()
		collection_type_info[self] = nil
	end
else
	function list_mt:Add(elem)
		table.insert(self, elem)
	end
end
function list_mt:Remove(elem)
	for i=1,#self do 
		if self[i] == elem then
			table.remove(self, i)
			return
		end
	end
end
function list_mt:Get(idx)
	return rawget(self, idx)
end
function list_mt:Size()
	return #self
end
function list_mt:GetRandom()
	local idx = math.random(1, #self)
	return self[idx]
end
function list_mt:Last()
	return self[#self]
end
function list_mt:Clear()
	for i=1,#self do
		self[i] = nil
	end
end
function list_mt:Iter()
	self.__cursor__ = 0
	return function (t)
		t.__cursor__ = t.__cursor__ + 1
		return t[t.__cursor__]
	end, self
end
-- client side dict implementation
dict_mt.__index = dict_mt
if DEBUG then
	function dict_mt:Add(k, v)
		local i = collection_type_info[self]
		typecheck_and_report(i.__keytype__, k)
		typecheck_and_report(i.__valtype__, v)
		rawset(self, k, v)
	end
	function dict_mt:__gc()
		collection_type_info[self] = nil
	end
else
	function dict_mt:Add(k, v)
		rawset(self, k, v)
	end
end
function dict_mt:Remove(k)
	rawset(self, k, nil)
end
function dict_mt:Get(k)
	return rawget(self, k)
end
function dict_mt:Size()
	local c = 0
	for _,_ in pairs(self) do
		c = c + 1
	end
	return c
end
if true then
--=======================================================
-- client side list implementation
if DEBUG then
	function new_dict(size, k, v)
		assert(k and v, "should specify key and value type of collection")
		local t = setmetatable({}, dict_mt)
		collection_type_info[t] = {
			__keytype__ = k,
			__valtype__ = v,
		}
		return t
	end
	function new_list(size, v)
		assert(v, "should specify value type of collection")
		local t = setmetatable({}, list_mt)
		collection_type_info[t] = {
			__keytype__ = v,
		}
		return t
	end
else
	function new_dict(size, k, v)
		return setmetatable({}, dict_mt)
	end
	function new_list(size, v)
		return setmetatable({}, list_mt)
	end
end
else
--=======================================================
-- server side dict/list impl
ffi = require 'engine.ffi'
memory = require 'engine.memory'
array = require 'engine.array'
hash = require 'engine.hash'
_string = require 'engine.string'
function new_dict(size, k, v)
	return memory.alloc(hash.new(k, v))
end
function new_list(size, v)
	return memory.alloc(array.new(v))
end	
end -- end of collection implementation



-- safely get data from dictoinary
local function value_from_dict(dict, k, default)
	local tp = type(dict)
	if tp == 'userdata' then
		return dict:ContainsKey(k) and dict[k] or default
	elseif tp == 'cdata' then
		local v = dict[k]
		if (not v) or (ffi.typeof(v):match('%*') and v == ffi.cast(ffi.typeof(v), 0)) then
			return default
		else
			return v
		end
	elseif tp == 'table' then
		return dict[k] or default
	else
		assert(false, "invalid dict type:"..tp)
	end
end 


-- protection: check type consistency on the fly (only when DEBUG is on)
local function protect(obj)
	return setmetatable({}, { __index = obj, 
		__newindex = function(t, key, value) 
			scplog("attempted to modify a read only table", key, value)
			error("modify readonly")
		end, 
		__metatable = false 
	})
end
local function protect2(obj)
	return setmetatable({}, { __index = obj, 
		__newindex = function(t, key, value) 
			local err = t.__class__:typecheck(key, value)
			if not err then
				local mt = debug.getmetatable(t)
				rawset(mt.__index, key, value)
			else
				scplog("assign error with typecheck:"..err)
				error(err)
			end
		end, 
		__metatable = false 
	})
end


-- wrapper: manage metatable for each script variable object.
-- to apply different metatable for each struct, we create dummy metaclass which is nothing new member added from base metaclass, 
-- and using it as actual class.
local wrapped_class_map = { __seed__ = 1 }
function wrap(mc, script_path)
	local tmp = wrapped_class_map
	local wc = tmp[script_path]
	if not wc then
		local wcname = ("%s__%d__"):format(mc.name, tmp.__seed__)
		-- generate wrapped class to original metatable by inheriting mc
		wc = _M[wcname][mc.name] 
		wc(wc, "") 
		local f, err = loadfile(ScriptLoader.SearchPath.."/"..script_path)
		if not f then
			scplog('loadfile error', err)
			error(err)
		end
		local methods = f()
		methods.__class__ = mc
		if ffi then
			local mt = {
				__index = function (t, k)
					local f = rawget(methods, k)
					return f or rawget(t, "_"..k)				
				end,
				__newindex = function (t, k, v)
					local real_k = "_"..k
					local curr_v = rawget(t, real_k)
					if curr_v == v then
						return
					end
					if type(v) == 'string' then
						rawset(t, real_k, _string.new(v))
					else
						rawset(t, real_k, v)
					end
					if curr_v ~= nil then
						memory.free(curr_v)
					end
				end
			}
			ffi.metatype(ffi.typeof(wcname), mt)
		else
			local mt = {
				__index = methods
			}
			wc.mt = mt
		end
		tmp[script_path] = wc
		tmp.__seed__ = tmp.__seed__ + 1
	end
	return wc
end



-- composer: build class and store information about it
local composer_mt = {}
composer_mt.__index = composer_mt
local function composer_method_missing(mt, k)
	local mc = metaclass[k]
	if not mc then
		scplog('no parent class', k)
		error("perent class does not exist. " .. k)
	end
	--scplog('import_decl', mc.name)
	local self = getmetatable(mt).__data
	self:import_decls(mc)
	self.parent = mc
	return self
end
local function composer_call(self, decl, decl2)
	-- because extend uses class.Hoge:Extend [[]] syntax, class.Hoge is passed to composer_call because of : operator.
	-- in such case self == decl because class.Hoge:Extend returns class.Hoge.
	-- otherwise (in case of class.Hoge [[]]) declaration is passed to here as 2nd arg.
	-- following line checks which argument is declaration.
	decl = (self == decl and decl2 or decl)
	--scplog('decl', decl)
	for type, name in self:parse(decl) do
		--scplog('type/name', type, name)
		table.insert(self.decls, { type, name })
		self.declmap[name] = type
	end	
	self:decl()
end
function composer_mt.create(k)
	if metaclass[k] then
		return metaclass[k]
	end
	local data = {
		name = k,
		decls = {},
		declmap = {},
		parent = false,
	}
	metaclass[k] = setmetatable(data, {
		__index = setmetatable(composer_mt, { 
			__data = data, 
			__index = composer_method_missing 
		}),
		__call = composer_call,
	})
	--scplog('mc created', k, metaclass[k].decls)
	return metaclass[k]
end
function composer_mt:derived_by(k)
	if k == self.name then
		return true
	end
	local cnt = 0
	local parent_meta = self.parent
	while parent_meta do
		if parent_meta.name == k then
			return true
		end
		parent_meta = parent_meta.parent
		cnt = cnt + 1
		if cnt >= 100 then
			assert(false, "invalid inheritance chain (too deep)")
		end
	end
end
function composer_mt:import_decls(meta)
	for i=1,#meta.decls do
		local d = meta.decls[i]
		table.insert(self.decls, d)
		self.declmap[d[2]] = d[1]
	end
end
function composer_mt:new_empty_object(plain)
	local p = ffi and memory.alloc_typed(self.name) or {}
	if not plain then
		self:fill_default(p)
	end
	return p
end
function composer_mt:fill_default(p)
	for k,v in pairs(self.declmap) do
		if not p[k] then
			if v == "int" or v == "double" or v == "float" then
				p[k] = 0
			elseif v == "string" then
				p[k] = nil
			elseif v == "bool" then
				p[k] = false
			elseif v == "object" then
				p[k] = nil
			elseif v:match(LIST_TYPE_MATCHER) then
				if ffi then
					p[k]:Clear()
				elseif DEBUG then
					p[k] = new_list(nil, v:match(LIST_TYPE_PARAM_INJECTOR))
				else
					p[k] = new_list()
				end
			elseif v:match(DICT_TYPE_MATCHER) then
				if ffi then 
					p[k]:Clear()
				elseif DEBUG then
					p[k] = new_dict(nil, v:match(DICT_TYPE_PARAM_INJECTOR))
				else
					p[k] = new_dict()
				end
			else
				local mc = metaclass[v] 
				if mc then
					--p[k] = mc:new_empty_object()
				else
					error("invalid typedef:["..k.."]["..v.."]")
				end
			end
		end
	end
end
function composer_mt:new(id, fixture)
	local p = self:new_empty_object(true)
	p.Id = id
	for k,v in iter(fixture) do
		local t = self.declmap[k] -- type information
		if not t then
			scplog("warn", "property name does not exist", k, self.name)
			-- no error. data will set by fill_default
		elseif t == "int" or t == "double" or t == "float" then
			assert(type(v) == 'number', "data error: number required but:"..type(v))
			p[k] = v
		elseif t == "string" then
			assert(type(v) == 'string', "data error: string required but:"..type(v))
			p[k] = ffi and ffi.cast('pulpo_string_t*', v) or v
		elseif t == "bool" then
			assert(type(v) == 'boolean', "data error: boolean required but:"..type(v))
			p[k] = v
		elseif t:match(LIST_TYPE_MATCHER) then
			assert(type(v) == 'table' and v.__IsList__, "data error: list required but:"..type(v).."|"..tostring(v.__IsList__))
			if ffi then
				local tmp = p[k]
				for e in iter(v) do
					tmp:Add(e)
				end
			else
				p[k] = v
			end
		elseif t:match(DICT_TYPE_MATCHER) then
			assert(type(v) == 'table' and (not v.__IsList__), "data error: dictionary required but:"..type(v).."|"..tostring(v.__IsList__))
			if ffi then
				local tmp = p[k]
				for key,val in iter(v) do
					tmp:Add(key,val)
				end
			else
				p[k] = v
			end
		else
			error("invalid typedef:["..k.."]["..v.."] only primitives and its collections are allowed")
		end
	end
	self:fill_default(p)
	return p
end
function composer_mt:parse(decl) 
	-- clean up comment lines
	decl = decl:gsub('%-%-[^%c]*%c', '')
	return decl:gmatch('(%a[%w,%s<>]*)%s+([%w]+);')
end
local function is_primitive_type(t)
	return t == "double" or t == "bool" or t == "float" or t == "int"
end
local function build_nested_generics_type(t)
	if t == "string" then
		return ffi.typeof('pulpo_string_t*')
	elseif t == "object" then
		return ffi.typeof('void *')
	elseif t:match(LIST_TYPE_MATCHER) then
		local v = t:match(LIST_TYPE_PARAM_INJECTOR)
		return array.new(build_nested_generics_type(v))
	elseif t:match(DICT_TYPE_MATCHER) then
		local k, v = t:match(DICT_TYPE_PARAM_INJECTOR)
		return hash.new(build_nested_generics_type(k), build_nested_generics_type(v))
	elseif is_primitive_type(t) then
		return ffi.typeof(t)
	else
		return ffi.typeof(("struct _%s *"):format(t))
	end
end
function composer_mt:decl_variable(d)
	local t = d[1]
	if t == 'string' then
		return ("$ *_%s;"):format(d[2]), ffi.typeof('pulpo_string_t')
	elseif t == 'object' then
		return ("void *%s;"):format(d[2])
	elseif t:match(LIST_TYPE_MATCHER) then
		return ("$ %s;"):format(d[2]), build_nested_generics_type(t)
	elseif t:match(DICT_TYPE_MATCHER) then
		return ("$ %s;"):format(d[2]), build_nested_generics_type(t)
	elseif is_primitive_type(t) then
		return ("%s %s;"):format(unpack(d))
	else
		return ("struct _%s *%s;"):format(unpack(d))
	end
end
function composer_mt:decl()
	if ffi then
		local parm_types = {}
		local declstr = {("typedef struct _%s {"):format(self.name)}
		for i=1,#self.decls do
			local src, pt = self:decl_variable(self.decls[i])
			table.insert(declstr, src)
			table.insert(parm_types, pt)
		end
		table.insert(declstr, ("} %s;"):format(self.name))
		scplog(table.concat(declstr))
		ffi.cdef(table.concat(declstr), unpack(parm_types))
	end
end
function composer_mt:typecheck(k, v)
	local t = self.declmap[k]
	if not t then
		for kk,vv in pairs(self.declmap) do
			scplog('typecheck', kk, vv, self.name)
		end
		return "no such variable:"..k
	end
	return typecheck(t, v)
end



-- vault: manage fix script data
local vault_mt = {}
vault_mt.__index = vault_mt
function vault_mt:initialize(datas)
	self.types = {}
	self.datas = datas
	local base_class_name = self.typeclass.name
	--scplog('start vault init', self.typeclass.name)
	for id, data in iter(datas) do
		-- scplog('init', id, data, value_from_dict(data, "TypeClass", base_class_name))
		local mc = metaclass[value_from_dict(data, "TypeClass", base_class_name)]
		if not mc:derived_by(base_class_name) then
			error(mc.name .. " does not inherit " .. base_class_name)
		end
		local o = mc:new(id, data)
		self.types[id] = DEBUG and protect(o) or o
	end
	--scplog('end vault init', self.typeclass.name)
end
function vault_mt:GetFixData(id)
	return self.types[id]
end



-- factory: manage variable script data
local factory_mt = {}
factory_mt.__index = factory_mt
function factory_mt:Create(id)
	if not self.vault then
		error('vault not set')
	end
	local t = self.vault:GetFixData(id)
	if not t then
		error("id does not exists:"..id)
	end
	local base_class_name = self.objclass.name
	local name = value_from_dict(t, "Class", base_class_name)
	local mc = metaclass[name]
	if not mc:derived_by(base_class_name) then
		error(mc.name .. " does not inherit " .. base_class_name)
	end
	if not mc.declmap.Type then
		error(mc.name .. " should have field which name is 'Type'")
	else
		local typemc = metaclass[value_from_dict(t, "TypeClass", self.vault.typeclass.name)]
		if not typemc:derived_by(self.vault.typeclass.name) then
			error(typemc.name .. " does not inherit " .. self.vault.typeclass.name)
		end
	end	
	local wc = wrap(mc, t.Script)
	local o = wc:new_empty_object()
	o.Type = t
	if not ffi then
		setmetatable(o, wc.mt)
	end
	return DEBUG and protect2(o) or o
end



-- main class module
local class_mt = {}
function class_mt:__index(k)
	return composer_mt.create(k)
end

function _M.init_fix_data(datas)
	_M.load_all_decls()
	for k, sources in iter(datas) do
		if vaults[k] then
			vaults[k]:initialize(sources)
		end
	end
end
function _M.vault(typeclass, category_name)
	local v = setmetatable({
		typeclass = typeclass,
	}, vault_mt)
	vaults[category_name] = v
	_G[category_name.."Vault"] = v
	return v
end
function _M.factory(objclass, category_name)
	local v = vaults[category_name]
	assert(v, "vault should be created for:"..category_name)
	local f = setmetatable({
		objclass = objclass,
		vault = v,
	}, factory_mt)
	_G[category_name.."Factory"] = f
	return f
end
local function load_decl_error_handler(e)
	return tostring(e).."\n"..debug.traceback()
end
function _M.load_all_decls()
	-- TODO : unify pattern spec
	local pattern = _G.ServerMode and ".*%.lua$" or "*.lua"
	grep("data/", pattern, function (f)
		local tmp = f:gsub('//+', '/'):match("data/(.+)%.lua$")
		local ok, r = xpcall(require, load_decl_error_handler, ('data.'..tmp:gsub('/', '.')))
		if not ok then
			scplog('load_all_decls', 'error', r)
			error(r)
		end
	end)
end
function _M.new(name, script_path)
	local mc = metaclass[name]
	local wc = wrap(mc, script_path)
	local o = wc:new_empty_object()
	if wc.mt then
		setmetatable(o, wc.mt)
	end
	return o
end
_M.new_list = new_list
_M.new_dict = new_dict
_M.list_mt = list_mt
_M.dict_mt = dict_mt

return setmetatable(_M, class_mt)

