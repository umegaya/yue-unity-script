require 'data.FixData'

class.EventTypeBase : FixData [[
	List<string> RandomList;
	List<string> FixedList;
	int Size;
]]
class.EventBase [[
	EventTypeBase Type;
]]

class.vault(class.EventTypeBase, "Events")
class.factory(class.EventBase, "Events")
