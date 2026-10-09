class_name SpawnCitizenCommand
extends Command

var tx: int
var ty: int
var race_id: int

func _init(x: int, y: int, r_id: int) -> void:
	tx = x
	ty = y
	race_id = r_id

func validate(state: WorldState) -> bool:
	var grid: TileGrid = state.tile_grid
	if not grid.in_bounds(tx, ty): return false
	var t: int = grid.terrain[grid.idx(tx, ty)]
	if t <= 1: return false # Không đẻ dưới nước
	return true

func execute(state: WorldState) -> void:
	state.citizens.spawn(float(tx) + 0.5, float(ty) + 0.5, race_id)
