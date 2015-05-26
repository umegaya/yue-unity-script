require 'data.FixData'

class.Partition [[
	Dictionary<string, List<User>> Users;
	Dictionary<string, List<ObjectBase>> Teams;
]]

class.CellTypeBase : FixData [[	
]]
class.CellBase [[
	CellTypeBase Type;
	Partition EnemySide;
	List<Partition> UserSide;
]]

class.vault(class.CellTypeBase, "Cells")
class.factory(class.CellBase, "Cells")

