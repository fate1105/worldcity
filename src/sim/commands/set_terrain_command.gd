class_name SetTerrainCommand
extends Command

var tx: int
var ty: int
var r: int
var terrain_type: int

func _init(x: int, y: int, radius: int, t_type: int) -> void:
	tx = x
	ty = y
	r = radius
	terrain_type = t_type

func validate(state: WorldState) -> bool:
	return true

func execute(state: WorldState) -> void:
	var grid: TileGrid = state.tile_grid
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			var nx: int = tx + dx
			var ny: int = ty + dy
			if grid.in_bounds(nx, ny):
				grid.set_terrain(nx, ny, terrain_type)
				grid.fire[grid.idx(nx, ny)] = 0
				EventBus.tile_changed.emit(nx, ny)
