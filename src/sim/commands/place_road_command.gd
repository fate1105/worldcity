class_name PlaceRoadCommand
extends Command

var tx: int
var ty: int
var remove: bool

func _init(x: int, y: int, is_remove: bool = false) -> void:
	tx = x
	ty = y
	remove = is_remove

func validate(state: WorldState) -> Error:
	var grid := state.tile_grid
	if not grid.in_bounds(tx, ty): return FAILED
	var t: int = grid.terrain[grid.idx(tx, ty)]
	if t <= 1 or t == 5 or t == 9: return FAILED
	var i: int = grid.idx(tx, ty)
	var has_road: bool = grid.road[i] > 0
	if remove and not has_road: return FAILED
	if not remove and has_road: return FAILED
	
	var cost: float = 2.0 # Giả sử phí xây đường = 2
	if remove: cost = 1.0 # Phí dỡ đường = 1
	var owner_id: int = grid.owner_id[i]
	if owner_id != -1 and state.kingdoms.has(owner_id):
		if state.kingdoms[owner_id].gold < cost:
			return FAILED
	else:
		if state.gold < cost:
			return FAILED
			
	return OK

func execute(state: WorldState) -> void:
	var grid := state.tile_grid
	var i: int = grid.idx(tx, ty)
	var cost: float = 2.0
	if remove: cost = 1.0
	var owner_id: int = grid.owner_id[i]
	if owner_id != -1 and state.kingdoms.has(owner_id):
		state.kingdoms[owner_id].gold -= cost
	else:
		state.gold -= cost
		
	grid.road[i] = 0 if remove else 1
	EventBus.tile_changed.emit(tx, ty)

func describe() -> String:
	return "%s Road at (%d, %d)" % ["Remove" if remove else "Place", tx, ty]
