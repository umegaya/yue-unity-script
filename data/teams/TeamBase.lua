require 'data.FixData'

class.TeamTypeBase : FixData [[
	-- friendly team id
	List<string> FriendlyTeams;
	-- hostile team id
	List<string> HostileTeams;
]]
class.TeamBase [[
	TeamTypeBase Type;
	-- objects belongs to this team
	Dictionary<int, ObjectBase> BelongsTo;
	-- user belongs to this team
	Dictionary<int, User> UserBelongsTo;
	-- current score
	int Score;
]]

class.vault(class.TeamTypeBase, "Teams")
class.factory(class.TeamBase, "Teams")
