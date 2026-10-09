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

func validate(state: WorldState) -> bool:
	var b_data: Dictionary = DataDB.building(b_type)
	if b_data.is_empty():
		return false
	
	var size: Array = b_data.get("size", [1, 1])
	var bw: int = int(size[0])
	var bh: int = int(size[1])
	var grid: TileGrid = state.tile_grid
	
	for dy in range(bh):
		for dx in range(bw):
			var nx: int = tx + dx
			var ny: int = ty + dy
			if not grid.in_bounds(nx, ny):
				return false
			var idx: int = grid.idx(nx, ny)
			if grid.building_id[idx] != -1 or grid.zone[idx] == TileGrid.ZoneType.NONE:
				return false
			if grid.terrain[idx] <= 1 or grid.terrain[idx] == 5 or grid.terrain[idx] == 9:
				return false
	return true

func execute(state: WorldState) -> void:
	var b_data: Dictionary = DataDB.building(b_type)
	var size: Array = b_data.get("size", [1, 1])
	var bw: int = int(size[0])
	var bh: int = int(size[1])
	var grid: TileGrid = state.tile_grid
	
	var building := Building.new(b_id, b_type, tx, ty, bw, bh)
	state.buildings[b_id] = building
	
	for dy in range(bh):
		for dx in range(bw):
			var idx: int = grid.idx(tx + dx, ty + dy)
			grid.building_id[idx] = b_id
			EventBus.tile_changed.emit(tx + dx, ty + dy)
	
	EventBus.building_placed.emit(b_id, tx, ty)
