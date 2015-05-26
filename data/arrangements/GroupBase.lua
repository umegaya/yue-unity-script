require 'data.FixData'

class.GroupTypeBase : FixData [[
	List<string> RandomList;
	List<string> FixedList;
	int Size;
]]
class.GroupBase [[
	GroupTypeBase Type;
]]

class.vault(class.GroupTypeBase, "Groups")
class.factory(class.GroupBase, "Groups")
