require 'data.objects.Character'

class.NPCObjectType : CharacterType [[
	int GainExp;
	int GainMoney;
	float WaitSec;
]]

class.NPCObject : Character [[
	float Cooldown;
]]

