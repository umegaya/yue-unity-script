require 'data.FixData'

class.ObjectTypeBase:FixData [[
	string DisplaySide;
]]
class.vault(class.ObjectTypeBase, "Objects")

class.ObjectBase [[
	int Id;
	ObjectTypeBase Type;
	Partition Partition;
	TeamBase Team;
	int X;
	int Y;
	bool IsDead;
]]
class.factory(class.ObjectBase, "Objects")
