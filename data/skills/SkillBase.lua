require 'data.FixData'

class.SkillTypeBase : FixData [[
	string Group;
	string Prefix;
	string Postfix;
	int Wp;
	List<string> AcceptGroups;
	string Range; --group size which this skill applied to
	string Scope; --group attribute (friend/enemy) which this skill applied to
	int Duration;
]]
class.SkillBase [[
	SkillTypeBase Type;
	int Duration;
]]

class.vault(class.SkillTypeBase, "Skills")
class.factory(class.SkillBase, "Skills")
