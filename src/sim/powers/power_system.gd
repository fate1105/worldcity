class_name PowerSystem
extends RefCounted

## Logic quyền năng thần (God powers) — không phụ thuộc Node
## Quản lý mana, thực thi quyền năng, lửa lan

## Tile nào có thể bốc cháy
const FLAMMABLE_TILES: Array[int] = [
	TileGrid.TileType.GRASS,
	TileGrid.TileType.FOREST,
	TileGrid.TileType.SAND,
]

## Màu sắc tile bị lửa (tham chiếu sang WorldView) — chỉ dùng ở đây để tài liệu
const FIRE_DURATION_DEFAULT: int = 120  # ticks

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

# ──────────────────────────────────────────────
# Mana
# ──────────────────────────────────────────────

## Gọi mỗi tick từ GameClock để hồi mana
func tick_mana(world_state: WorldState, delta: float) -> void:
	var regen: float = DataDB.balance("mana").get("regen_per_second", 1.0)
	var old_mana: float = world_state.mana
	world_state.mana = minf(world_state.mana + regen * delta, world_state.max_mana)
	if absf(world_state.mana - old_mana) > 0.01:
		EventBus.mana_changed.emit(world_state.mana, world_state.max_mana)

## Trừ mana, trả về false nếu không đủ
func spend_mana(world_state: WorldState, amount: float) -> bool:
	if world_state.mana < amount:
		return false
	world_state.mana -= amount
	EventBus.mana_changed.emit(world_state.mana, world_state.max_mana)
	return true

# ──────────────────────────────────────────────
# Quyền năng
# ──────────────────────────────────────────────

## Thực thi quyền năng tại (tx, ty). Trả về true nếu thành công.
func apply_power(power_id: String, tx: int, ty: int,
				world_state: WorldState) -> bool:
	var pdata: Dictionary = DataDB.power(power_id)
	if pdata.is_empty():
		return false

	var mana_cost: float = float(pdata.get("mana", 0))
	if not spend_mana(world_state, mana_cost):
		push_warning("PowerSystem: không đủ mana cho '%s'" % power_id)
		return false

	var radius: int = int(pdata.get("radius", 0))
	var effect: String = str(pdata.get("effect", ""))
	var grid: TileGrid = world_state.tile_grid

	match effect:
		"rain":
			_apply_rain(tx, ty, radius, int(pdata.get("duration", 100)),
						int(pdata.get("fertility_gain", 10)), grid)
		"damage":
			_apply_lightning(tx, ty, float(pdata.get("ignite", 0.3)), grid)
		"ignite":
			_apply_fire(tx, ty, radius, grid)
		"volcano":
			_apply_volcano(tx, ty, radius, float(pdata.get("lava_spread", 0.15)), grid)
		_:
			push_warning("PowerSystem: effect '%s' chưa được thực thi" % effect)
			return false

	EventBus.power_used.emit(power_id, tx, ty)
	return true

# ──────────────────────────────────────────────
# Hiệu ứng cụ thể
# ──────────────────────────────────────────────

func _apply_rain(cx: int, cy: int, radius: int, duration: int,
				fertility_gain: int, grid: TileGrid) -> void:
	for dy: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var tx: int = cx + dx
			var ty: int = cy + dy
			if not grid.in_bounds(tx, ty):
				continue
			var i: int = grid.idx(tx, ty)
			# Dập lửa
			grid.fire[i] = 0
			# Tăng fertility cho đất
			var t: int = grid.terrain[i]
			if t in FLAMMABLE_TILES:
				grid.fertility[i] = mini(int(grid.fertility[i]) + fertility_gain, 255)
	# Đánh dấu dirty vùng chunk ảnh hưởng
	_mark_dirty_region(cx, cy, radius)

func _apply_lightning(cx: int, cy: int, ignite_chance: float,
					grid: TileGrid) -> void:
	# Sét đánh 1 ô — hiệu ứng damage (sẽ ảnh hưởng dân ở Milestone 4)
	if not grid.in_bounds(cx, cy):
		return
	# Có thể gây cháy
	if _rng.randf() < ignite_chance:
		_set_fire(cx, cy, grid, FIRE_DURATION_DEFAULT)
	_mark_dirty_region(cx, cy, 1)

func _apply_fire(cx: int, cy: int, radius: int, grid: TileGrid) -> void:
	for dy: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			_set_fire(cx + dx, cy + dy, grid, FIRE_DURATION_DEFAULT)
	_mark_dirty_region(cx, cy, radius)

func _apply_volcano(cx: int, cy: int, radius: int,
					lava_chance: float, grid: TileGrid) -> void:
	for dy: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			var dist2: int = dx * dx + dy * dy
			var tx: int = cx + dx
			var ty: int = cy + dy
			if not grid.in_bounds(tx, ty):
				continue
			var i: int = grid.idx(tx, ty)
			if dist2 <= 2:
				# Tâm → núi
				grid.terrain[i] = TileGrid.TileType.MOUNTAIN
				grid.fire[i] = 0
			elif _rng.randf() < lava_chance:
				# Xung quanh → dung nham
				grid.terrain[i] = TileGrid.TileType.LAVA
				grid.fire[i] = 0
			else:
				# Vùng ngoài → bốc cháy
				_set_fire(tx, ty, grid, FIRE_DURATION_DEFAULT + _rng.randi_range(0, 60))
	_mark_dirty_region(cx, cy, radius)

# ──────────────────────────────────────────────
# Lửa lan (gọi mỗi ngày)
# ──────────────────────────────────────────────

func process_fire(grid: TileGrid) -> void:
	var w: int = grid.width
	var h: int = grid.height
	var spread_chance: float = 0.25

	for y: int in range(h):
		for x: int in range(w):
			var i: int = grid.idx(x, y)
			if grid.fire[i] == 0:
				continue
			# Giảm timer
			if grid.fire[i] > 1:
				grid.fire[i] -= 1
			else:
				grid.fire[i] = 0
				# Ô cháy hết → thành đất trống
				if grid.terrain[i] == TileGrid.TileType.FOREST:
					grid.terrain[i] = TileGrid.TileType.GRASS
				continue

			# Lan ra 4 hướng
			for dir: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx: int = x + dir.x
				var ny: int = y + dir.y
				if not grid.in_bounds(nx, ny):
					continue
				var ni: int = grid.idx(nx, ny)
				if grid.fire[ni] > 0:
					continue  # đã cháy rồi
				var neighbor_type: int = grid.terrain[ni]
				if neighbor_type in FLAMMABLE_TILES and _rng.randf() < spread_chance:
					grid.fire[ni] = FIRE_DURATION_DEFAULT + _rng.randi_range(0, 40)

# ──────────────────────────────────────────────
# Tiện ích
# ──────────────────────────────────────────────

func _set_fire(tx: int, ty: int, grid: TileGrid, duration: int) -> void:
	if not grid.in_bounds(tx, ty):
		return
	var i: int = grid.idx(tx, ty)
	if grid.terrain[i] in FLAMMABLE_TILES or grid.terrain[i] == TileGrid.TileType.LAVA:
		grid.fire[i] = duration

func _mark_dirty_region(cx: int, cy: int, radius: int) -> void:
	# WorldView sẽ lắng nghe signal tile_changed hoặc nhận dirty marks trực tiếp
	# Ở đây phát signal để view xử lý
	var chunk_size: int = 32  # khớp WorldView.CHUNK_SIZE
	var cx_min: int = (cx - radius) / chunk_size
	var cy_min: int = (cy - radius) / chunk_size
	var cx_max: int = (cx + radius) / chunk_size
	var cy_max: int = (cy + radius) / chunk_size
	for ccy: int in range(cy_min, cy_max + 1):
		for ccx: int in range(cx_min, cx_max + 1):
			EventBus.tile_changed.emit(ccx * chunk_size, ccy * chunk_size)
