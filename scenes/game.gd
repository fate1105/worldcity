extends Node2D

## Script cho scene game.tscn — điều phối toàn bộ game
## Milestone 1: WorldState, WorldGen, WorldView, Camera
## Milestone 2: DataDB, GameClock, HUD

@onready var _camera: CameraController = $CameraController
@onready var _world_view: WorldView = $WorldView
@onready var _label_fps: Label = $DebugOverlay/Panel/VBox/LabelFPS
@onready var _label_info: Label = $DebugOverlay/Panel/VBox/LabelInfo

const MAP_WIDTH: int = 128
const MAP_HEIGHT: int = 128
const TILE_PX: int = 16  # phải khớp WorldView.TILE_PX

var _world_state: WorldState

func _ready() -> void:
	# Nạp dữ liệu JSON
	DataDB.load_all()

	# Tạo world state và sinh bản đồ
	var seed_val: int = randi()
	_world_state = WorldState.new(MAP_WIDTH, MAP_HEIGHT, seed_val)
	WorldGen.generate(_world_state, seed_val)

	# Đồng bộ thời gian từ WorldState vào GameClock
	GameClock.sync_from_world(_world_state)

	# Khởi tạo camera với giới hạn
	_camera.setup_limits(MAP_WIDTH, MAP_HEIGHT, TILE_PX)

	# Khởi tạo WorldView
	_world_view.setup(_world_state, _camera)

	push_warning("WorldCity seed: %d" % seed_val)

func _process(_delta: float) -> void:
	_label_fps.text = "FPS: %d  |  Tick: %d" % [
		Engine.get_frames_per_second(),
		GameClock.tick
	]
	_label_info.text = "Map: %dx%d  |  Seed: %d" % [
		MAP_WIDTH, MAP_HEIGHT, _world_state.rng_seed
	]
