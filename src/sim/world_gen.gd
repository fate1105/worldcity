class_name WorldGen
extends RefCounted

## Ngưỡng chuyển loại ô (0.0-1.0 của noise đã chuẩn hoá về [0,1])
const THRESHOLD_DEEP_SEA: float    = 0.35
const THRESHOLD_SHALLOW_SEA: float = 0.42
const THRESHOLD_SAND: float        = 0.46
const THRESHOLD_GRASS: float       = 0.68
const THRESHOLD_FOREST: float      = 0.78
const THRESHOLD_MOUNTAIN: float    = 0.88
# trên MOUNTAIN → SNOW

## Sinh bản đồ vào TileGrid theo seed
## Trả về WorldState đã được điền dữ liệu
static func generate(world_state: WorldState, seed_val: int) -> void:
	world_state.rng_seed = seed_val

	var w: int = world_state.map_width
	var h: int = world_state.map_height
	var grid: TileGrid = world_state.tile_grid

	# --- Noise 1: Height (quyết định biển / đất / núi) ---
	var noise_height := FastNoiseLite.new()
	noise_height.seed = seed_val
	noise_height.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_height.frequency = 0.025
	noise_height.fractal_octaves = 5
	noise_height.fractal_lacunarity = 2.0
	noise_height.fractal_gain = 0.5

	# --- Noise 2: Moisture (quyết định rừng / sa mạc / đầm lầy) ---
	var noise_moisture := FastNoiseLite.new()
	noise_moisture.seed = seed_val + 1
	noise_moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_moisture.frequency = 0.04
	noise_moisture.fractal_octaves = 3

	for y: int in range(h):
		for x: int in range(w):
			var i: int = grid.idx(x, y)

			# Noise trả về [-1, 1] → chuẩn hoá về [0, 1]
			var raw_h: float = noise_height.get_noise_2d(float(x), float(y))
			var hn: float = (raw_h + 1.0) * 0.5

			var raw_m: float = noise_moisture.get_noise_2d(float(x), float(y))
			var mn: float = (raw_m + 1.0) * 0.5

			# Lưu height_map (0-255)
			grid.height_map[i] = int(hn * 255.0)

			# Quyết định loại ô theo height + moisture
			var tile_type: int = _classify(hn, mn)
			grid.terrain[i] = tile_type

			# Fertility: đất cỏ/rừng cao, biển/núi/tuyết thấp
			grid.fertility[i] = _calc_fertility(tile_type, hn, mn)

## Phân loại ô theo height và moisture
static func _classify(hn: float, mn: float) -> int:
	if hn < THRESHOLD_DEEP_SEA:
		return TileGrid.TileType.DEEP_SEA
	elif hn < THRESHOLD_SHALLOW_SEA:
		return TileGrid.TileType.SHALLOW_SEA
	elif hn < THRESHOLD_SAND:
		return TileGrid.TileType.SAND
	elif hn < THRESHOLD_GRASS:
		# Moisture quyết định grass / desert / swamp
		if mn < 0.3:
			return TileGrid.TileType.DESERT
		elif mn > 0.75 and hn < 0.55:
			return TileGrid.TileType.SWAMP
		else:
			return TileGrid.TileType.GRASS
	elif hn < THRESHOLD_FOREST:
		if mn < 0.25:
			return TileGrid.TileType.DESERT
		else:
			return TileGrid.TileType.FOREST
	elif hn < THRESHOLD_MOUNTAIN:
		return TileGrid.TileType.MOUNTAIN
	else:
		return TileGrid.TileType.SNOW

static func _calc_fertility(tile_type: int, hn: float, mn: float) -> int:
	match tile_type:
		TileGrid.TileType.GRASS:
			return int(mn * 200.0 + 55.0)
		TileGrid.TileType.FOREST:
			return int(mn * 150.0 + 80.0)
		TileGrid.TileType.SWAMP:
			return 120
		TileGrid.TileType.SAND:
			return 30
		TileGrid.TileType.DESERT:
			return 10
		TileGrid.TileType.MOUNTAIN, TileGrid.TileType.SNOW:
			return 15
		_:
			return 0
