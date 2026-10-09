class_name PlaceRoadCommand
extends Command

var tx: int
var ty: int
var remove: bool

func _init(x: int, y: int, is_remove: bool = false) -> void:
	tx = x
	ty = y
	remove = is_remove

func validate(state: WorldState) -> bool:
	var grid := state.tile_grid
	if not grid.in_bounds(tx, ty): return false
	var t: int = grid.terrain[grid.idx(tx, ty)]
	if t <= 1 or t == 5 or t == 9: return false # Không xây đường trên biển, núi, dung nham
	var i: int = grid.idx(tx, ty)
	var has_road: bool = grid.road[i] > 0
	if remove and not has_road: return false
	if not remove and has_road: return false
	return true

func execute(state: WorldState) -> void:
	var grid := state.tile_grid
	var i: int = grid.idx(tx, ty)
	grid.road[i] = 0 if remove else 1
	EventBus.tile_changed.emit(tx, ty)
