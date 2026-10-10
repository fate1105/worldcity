class_name PlaceBuildingCommand
extends Command

var tx: int
var ty: int
var b_type: String
var b_id: int

func _init(x: int, y: int, building_type: String, new_b_id: int) -> void:
	tx = x
	ty = y
	b_type = building_type
	b_id = new_b_id

func validate(state: WorldState) -> Error:
	var b_data: Dictionary = DataDB.building(b_type)
	if b_data.is_empty():
		return FAILED
	
	var size: Array = b_data.get("size", [1, 1])
	var bw: int = int(size[0])
	var bh: int = int(size[1])
	var grid: TileGrid = state.tile_grid
	
	var terrain_map: Dictionary = {
		"deep_water": 0, "shallow_water": 1, "sand": 2, "grass": 3,
		"forest": 4, "mountain": 5, "snow": 6, "desert": 7, "swamp": 8, "lava": 9
	}
	
	var terrain_ok_str: Array = b_data.get("terrain_ok", [])
	var terrain_near_str: Array = b_data.get("terrain_near", [])
	
	var terrain_ok: Array[int] = []
	for s in terrain_ok_str: terrain_ok.append(terrain_map.get(s, -1))
	var terrain_near: Array[int] = []
	for s in terrain_near_str: terrain_near.append(terrain_map.get(s, -1))

	var is_near_ok: bool = false
	if terrain_near.is_empty(): is_near_ok = true
	
	for dy in range(bh):
		for dx in range(bw):
			var nx: int = tx + dx
			var ny: int = ty + dy
			if not grid.in_bounds(nx, ny):
				return FAILED
			var idx: int = grid.idx(nx, ny)
			if grid.building_id[idx] != -1:
				return FAILED
			
			var t: int = grid.terrain[idx]
			if t <= 1 or t == 5 or t == 9:
				return FAILED
				
			if not terrain_ok.is_empty() and not terrain_ok.has(t):
				return FAILED
				
			if not is_near_ok:
				for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var ax: int = nx + d.x
					var ay: int = ny + d.y
					if grid.in_bounds(ax, ay) and terrain_near.has(grid.terrain[grid.idx(ax, ay)]):
						is_near_ok = true
						
	if not is_near_ok:
		return FAILED
	var cost: float = float(b_data.get("cost", 0))
	var owner_id: int = grid.owner_id[grid.idx(tx, ty)]
	if owner_id != -1 and state.kingdoms.has(owner_id):
		if state.kingdoms[owner_id].gold < cost:
			return FAILED
	else:
		if state.gold < cost:
			return FAILED

	return OK

func execute(state: WorldState) -> void:
	var b_data: Dictionary = DataDB.building(b_type)
	var size: Array = b_data.get("size", [1, 1])
	var bw: int = int(size[0])
	var bh: int = int(size[1])
	var grid: TileGrid = state.tile_grid
	
	var cost: float = float(b_data.get("cost", 0))
	var owner_id: int = grid.owner_id[grid.idx(tx, ty)]
	if owner_id != -1 and state.kingdoms.has(owner_id):
		state.kingdoms[owner_id].gold -= cost
	else:
		state.gold -= cost
		
	var building := Building.new(b_id, b_type, tx, ty, bw, bh)
	state.buildings[b_id] = building
	
	for dy in range(bh):
		for dx in range(bw):
			var idx: int = grid.idx(tx + dx, ty + dy)
			grid.building_id[idx] = b_id
			EventBus.tile_changed.emit(tx + dx, ty + dy)
	
	EventBus.building_placed.emit(b_id, tx, ty)

func describe() -> String:
	return "Place %s at (%d, %d)" % [b_type, tx, ty]
