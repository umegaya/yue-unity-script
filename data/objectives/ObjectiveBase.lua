require 'data.FixData'

class.ObjectiveTypeBase : FixData [[
	string AssignedTeam;
	string Group;
]]
class.ObjectiveBase [[
	ObjectiveTypeBase Type;
]]

class.vault(class.ObjectiveTypeBase, "Objectives")
class.factory(class.ObjectiveBase, "Objectives")
