class_name WorldState
extends RefCounted

# Kích thước bản đồ
var map_width: int = 128
var map_height: int = 128

# Seed RNG (lưu để tái hiện)
var rng_seed: int = 0

# Tham chiếu đến lưới ô
var tile_grid: TileGrid

# Thời gian
var tick: int = 0
var day: int = 1
var month: int = 1
var year: int = 1

func _init(width: int = 128, height: int = 128, seed_val: int = 0) -> void:
	map_width = width
	map_height = height
	rng_seed = seed_val
	tile_grid = TileGrid.new(width, height)

func to_dict() -> Dictionary:
	return {
		"map_width": map_width,
		"map_height": map_height,
		"rng_seed": rng_seed,
		"tick": tick,
		"day": day,
		"month": month,
		"year": year,
		"tile_grid": tile_grid.to_dict(),
	}

static func from_dict(d: Dictionary) -> WorldState:
	var ws := WorldState.new(d.get("map_width", 128), d.get("map_height", 128), d.get("rng_seed", 0))
	ws.tick = d.get("tick", 0)
	ws.day = d.get("day", 1)
	ws.month = d.get("month", 1)
	ws.year = d.get("year", 1)
	ws.tile_grid = TileGrid.from_dict(d.get("tile_grid", {}))
	return ws
