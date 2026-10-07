extends Node2D

## Điều phối toàn bộ game
## M1: WorldState, WorldGen, WorldView, Camera
## M2: DataDB, GameClock, HUD
## M3: PowerSystem, Toolbar, input routing (terrain brush + god powers)

@onready var _camera: CameraController    = $CameraController
@onready var _world_view: WorldView        = $WorldView
@onready var _toolbar: Toolbar             = $Toolbar
@onready var _label_fps: Label             = $DebugOverlay/Panel/VBox/LabelFPS
@onready var _label_info: Label            = $DebugOverlay/Panel/VBox/LabelInfo

const MAP_WIDTH: int  = 128
const MAP_HEIGHT: int = 128
const TILE_PX: int    = 16  # phải khớp WorldView.TILE_PX

var _world_state: WorldState
var _power_system: PowerSystem
var _rng: RandomNumberGenerator

# --- Trạng thái công cụ ---
enum ToolMode { NONE, TERRAIN, POWER }
var _tool_mode: ToolMode   = ToolMode.TERRAIN
var _active_terrain: int   = TileGrid.TileType.GRASS
var _active_power: String  = ""
var _brush_size: int       = 1
var _mouse_held: bool      = false

# --- Tích luỹ thời gian để hồi mana ---
var _mana_accum: float = 0.0

func _ready() -> void:
	DataDB.load_all()

	# RNG có seed
	_rng = RandomNumberGenerator.new()
	var seed_val: int = randi()
	_rng.seed = seed_val

	# Tạo world và sinh bản đồ
	_world_state = WorldState.new(MAP_WIDTH, MAP_HEIGHT, seed_val)
	_world_state.max_mana = float(DataDB.balance("mana").get("max", 100))
	_world_state.mana     = _world_state.max_mana
	WorldGen.generate(_world_state, seed_val)

	# PowerSystem
	_power_system = PowerSystem.new(_rng)

	# Đồng bộ clock
	GameClock.sync_from_world(_world_state)

	# Camera
	_camera.setup_limits(MAP_WIDTH, MAP_HEIGHT, TILE_PX)

	# WorldView
	_world_view.setup(_world_state, _camera)

	# Toolbar signals
	_toolbar.terrain_selected.connect(_on_terrain_selected)
	_toolbar.power_selected.connect(_on_power_selected)
	_toolbar.brush_size_changed.connect(_on_brush_size_changed)

	# Clock signals
	EventBus.tick_happened.connect(_on_tick)
	EventBus.day_passed.connect(_on_day_passed)

	# Phát mana ban đầu lên HUD
	EventBus.mana_changed.emit(_world_state.mana, _world_state.max_mana)

	push_warning("WorldCity seed: %d" % seed_val)

# ──────────────────────────────────────────────
# Tick / Ngày
# ──────────────────────────────────────────────

func _on_tick(_tick_num: int) -> void:
	# Hồi mana theo delta thực (dùng physics delta ≈ 1/tick_rate)
	var delta: float = 1.0 / float(GameClock.TICKS_PER_SECOND)
	_power_system.tick_mana(_world_state, delta * float(GameClock.speed))

func _on_day_passed(_day: int, _month: int, _year: int) -> void:
	# Lửa lan mỗi ngày
	_power_system.process_fire(_world_state.tile_grid)
	# Đánh dirty toàn bộ chunk chứa lửa (WorldView tự kiểm tra)
	_mark_fire_dirty()

func _mark_fire_dirty() -> void:
	var grid: TileGrid = _world_state.tile_grid
	for y: int in range(0, MAP_HEIGHT, WorldView.CHUNK_SIZE):
		for x: int in range(0, MAP_WIDTH, WorldView.CHUNK_SIZE):
			# Kiểm tra nhanh: có ô lửa trong chunk không?
			var has_fire: bool = false
			for dy: int in range(mini(WorldView.CHUNK_SIZE, MAP_HEIGHT - y)):
				for dx: int in range(mini(WorldView.CHUNK_SIZE, MAP_WIDTH - x)):
					if grid.fire[grid.idx(x + dx, y + dy)] > 0:
						has_fire = true
						break
				if has_fire:
					break
			if has_fire:
				_world_view.mark_dirty(x, y)

# ──────────────────────────────────────────────
# Input
# ──────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_mouse_held = mb.pressed
			if mb.pressed:
				_apply_tool_at(mb.position)

	elif event is InputEventMouseMotion and _mouse_held:
		var mm := event as InputEventMouseMotion
		_apply_tool_at(mm.position)

	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_mouse_held = touch.pressed
		if touch.pressed:
			_apply_tool_at(touch.position)

	elif event is InputEventScreenDrag and _mouse_held:
		var drag := event as InputEventScreenDrag
		_apply_tool_at(drag.position)

func _apply_tool_at(screen_pos: Vector2) -> void:
	var tile_pos: Vector2i = _screen_to_tile(screen_pos)
	match _tool_mode:
		ToolMode.TERRAIN:
			_paint_terrain(tile_pos.x, tile_pos.y)
		ToolMode.POWER:
			_use_power(tile_pos.x, tile_pos.y)

func _screen_to_tile(screen_pos: Vector2) -> Vector2i:
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	return Vector2i(int(world_pos.x / TILE_PX), int(world_pos.y / TILE_PX))

func _paint_terrain(cx: int, cy: int) -> void:
	var half: int = _brush_size / 2
	var grid: TileGrid = _world_state.tile_grid
	for dy: int in range(-half, half + 1):
		for dx: int in range(-half, half + 1):
			var tx: int = cx + dx
			var ty: int = cy + dy
			if grid.in_bounds(tx, ty):
				grid.set_terrain(tx, ty, _active_terrain)
				# Xoá lửa khi vẽ đè
				grid.fire[grid.idx(tx, ty)] = 0
				_world_view.mark_dirty(tx, ty)

func _use_power(tx: int, ty: int) -> void:
	if _active_power.is_empty():
		return
	_power_system.apply_power(_active_power, tx, ty, _world_state)

# ──────────────────────────────────────────────
# Toolbar callbacks
# ──────────────────────────────────────────────

func _on_terrain_selected(terrain_type: int) -> void:
	_active_terrain = terrain_type
	_tool_mode = ToolMode.TERRAIN

func _on_power_selected(power_id: String) -> void:
	_active_power = power_id
	_tool_mode = ToolMode.POWER

func _on_brush_size_changed(size: int) -> void:
	_brush_size = size

# ──────────────────────────────────────────────
# Debug overlay
# ──────────────────────────────────────────────

func _process(_delta: float) -> void:
	_label_fps.text = "FPS: %d  |  Tick: %d  |  Mana: %d" % [
		Engine.get_frames_per_second(),
		GameClock.tick,
		int(_world_state.mana)
	]
	_label_info.text = "Map: %dx%d  |  Seed: %d  |  Tool: %s" % [
		MAP_WIDTH, MAP_HEIGHT, _world_state.rng_seed,
		_get_tool_label()
	]

func _get_tool_label() -> String:
	match _tool_mode:
		ToolMode.TERRAIN:
			return "Địa hình [%dx%d]" % [_brush_size, _brush_size]
		ToolMode.POWER:
			return "Quyền năng: %s" % _active_power
	return "Không"
