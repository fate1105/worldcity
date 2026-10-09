class_name DemolishCommand
extends Command

var tx: int
var ty: int
var r: int

func _init(x: int, y: int, radius: int = 0) -> void:
	tx = x
	ty = y
	r = radius

func validate(_state: WorldState) -> Error:
	return OK

func execute(state: WorldState) -> void:
	var grid: TileGrid = state.tile_grid
	for y: int in range(ty - r, ty + r + 1):
		for x: int in range(tx - r, tx + r + 1):
			if grid.in_bounds(x, y):
				var idx: int = grid.idx(x, y)
				var b_id: int = grid.building_id[idx]
				
				# Xoá công trình
				if b_id != -1:
					if state.buildings.has(b_id):
						var b: Building = state.buildings[b_id]
						# Xoá toàn bộ ô của công trình này
						for dy in range(b.height):
							for dx in range(b.width):
								var nx: int = b.x + dx
								var ny: int = b.y + dy
								if grid.in_bounds(nx, ny):
									grid.building_id[grid.idx(nx, ny)] = -1
									EventBus.tile_changed.emit(nx, ny)
						state.buildings.erase(b_id)
						EventBus.building_removed.emit(b_id)
				
				# Xoá đường
				if grid.road[idx] > 0:
					grid.road[idx] = 0
					EventBus.tile_changed.emit(x, y)

func describe() -> String:
	return "Demolish at (%d, %d) r=%d" % [tx, ty, r]
