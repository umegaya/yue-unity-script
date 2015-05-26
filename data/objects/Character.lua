require 'data.objects.ObjectBase'

class.CharacterType : ObjectTypeBase [[
	int MaxHp;
	int MaxWp;
	int Attack;
	int Defense;
	List<string> Skills;
]]

class.Character : ObjectBase [[
	List<SkillBase> Skills;
	List<SkillBase> Effects;
	List<ActionResult> ActionQueue;
	List<ActionResult> ComboChain;
	bool IsDead;
	int MaxHp;
	int Hp;
	int MaxWp;
	int Wp;
	int Attack;
	int Defense;
	int LastUpdateQueue;
]]
