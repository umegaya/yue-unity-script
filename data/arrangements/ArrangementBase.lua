require 'data.FixData'
-- group pattern container for logical arrangement unit (eg. normal stage for single play or place ment for multi play mode)
class.ArrangementTypeBase : FixData [[
	-- what group pops for which team
	Dictionary<string, List<string>> TeamMemberLists;
]]
class.ArrangementBase [[
	ArrangementTypeBase Type;
]]

class.vault(class.ArrangementTypeBase, "Arrangements")
class.factory(class.ArrangementBase, "Arrangements")
