require 'data.objects.User'

class.GameUserType : ObjectTypeBase [[
	float WaitSec;	
]]
class.GameUser : User [[
	ObjectiveBase Objective;
	List<ObjectBase> Heroes;
	float LastCmdTime;
	float WaitSec;
]]
