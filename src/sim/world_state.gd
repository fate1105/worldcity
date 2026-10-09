class_name WorldState
extends RefCounted

# Kích thước bản đồ
var map_width: int = 128
var map_height: int = 128

# Seed RNG (lưu để tái hiện)
var rng_seed: int = 0

# Tham chiếu đến lưới ô
var tile_grid: TileGrid

# Tham chiếu đến tập dân cư
var citizens: CitizenStore
var citizen_names: CitizenNames

# RNG mô phỏng chung
var rng: RandomNumberGenerator

# Danh sách các công trình (Dictionary: id -> Building)
var buildings: Dictionary = {}
var next_building_id: int = 1

# Danh sách vương quốc (Dictionary: id -> Kingdom)
var kingdoms: Dictionary = {}
var next_kingdom_id: int = 1

# Thời gian
var tick: int = 0
var day: int = 1
var month: int = 1
var year: int = 1

# Mana (God mode)
var mana: float = 100.0
var max_mana: float = 100.0

# Tài nguyên kinh tế (dùng chung toàn thế giới; từ M9 mỗi Kingdom có riêng)
var gold: float = 1000.0
var food: float = 200.0
var wood: float = 50.0
var stone: float = 20.0

# Ngân sách: số tháng liên tiếp bị thâm hụt (nếu >= 3 thì bất ổn)
var deficit_months: int = 0

func _init(width: int = 128, height: int = 128, seed_val: int = 0) -> void:
	map_width = width
	map_height = height
	rng_seed = seed_val
	rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	tile_grid = TileGrid.new(width, height)
	citizens = CitizenStore.new()
	citizen_names = CitizenNames.new(rng)

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
		# TODO: Lên kế hoạch lưu công trình sau
	}

static func from_dict(d: Dictionary) -> WorldState:
	var ws := WorldState.new(d.get("map_width", 128), d.get("map_height", 128), d.get("rng_seed", 0))
	ws.tick = d.get("tick", 0)
	ws.day = d.get("day", 1)
	ws.month = d.get("month", 1)
	ws.year = d.get("year", 1)
	ws.tile_grid = TileGrid.from_dict(d.get("tile_grid", {}))
	return ws
