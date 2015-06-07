class.FieldBase [[
	-- object's id seed
	int IdSeed;
	
	-- collection of all cells in fields
	List<List<CellBase>> Cells;
	
	-- x, y of cell size
	int SizeX;
	int SizeY;
	
	-- all team in field
	Dictionary<string, TeamBase> Teams;
	
	-- all objectives
	Dictionary<string, ObjectiveBase> Objectives;
	
	-- all events
	List<EventBase> Events;
	
	-- object arrangement
	ArrangementBase Arrangement;
	
	-- last update
	float LastUpdate;
	
	-- this field finished?
	bool Finished;
	
	-- id - object mapping
	Dictionary<int, ObjectBase> ObjectMap;
]]
