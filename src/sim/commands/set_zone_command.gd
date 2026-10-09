class_name SetZoneCommand
extends Command

var tx: int
var ty: int
var r: int
var zone_type: int

func _init(x: int, y: int, radius: int, z_type: int) -> void:
	tx = x
	ty = y
	r = radius
	zone_type = z_type

func validate(_state: WorldState) -> Error:
	return OK

func execute(state: WorldState) -> void:
	var grid: TileGrid = state.tile_grid
	for y: int in range(ty - r, ty + r + 1):
		for x: int in range(tx - r, tx + r + 1):
			if grid.in_bounds(x, y):
				var i: int = grid.idx(x, y)
				# Nếu đã có công trình, có thể không cho phép đổi zone, nhưng hiện tại cứ ghi đè
				grid.zone[i] = zone_type
				EventBus.tile_changed.emit(x, y)

func describe() -> String:
	return "Set Zone %d at (%d, %d) r=%d" % [zone_type, tx, ty, r]
