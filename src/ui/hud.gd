extends CanvasLayer

## HUD chính — hiện thị thời gian và nút điều khiển tốc độ
## Nhận event từ EventBus, không đọc state trực tiếp mỗi frame

@onready var _label_time: Label     = $TopBar/HBoxMain/HBoxTime/LabelTime
@onready var _btn_pause: Button     = $TopBar/HBoxMain/HBoxSpeed/BtnPause
@onready var _btn_1x: Button        = $TopBar/HBoxMain/HBoxSpeed/Btn1x
@onready var _btn_2x: Button        = $TopBar/HBoxMain/HBoxSpeed/Btn2x
@onready var _btn_5x: Button        = $TopBar/HBoxMain/HBoxSpeed/Btn5x

@onready var _panel_info: PanelContainer = $PanelInfo
@onready var _label_title: Label         = $PanelInfo/VBox/LabelTitle
@onready var _label_stats: Label         = $PanelInfo/VBox/LabelStats

var _tracked_citizen_id: int = -1
var _world_state_ref: WorldState

func _ready() -> void:
	# Kết nối signal từ EventBus
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.speed_changed.connect(_on_speed_changed)

	# Kết nối nút tốc độ
	_btn_pause.pressed.connect(func() -> void: GameClock.set_speed(0))
	_btn_1x.pressed.connect(func() -> void: GameClock.set_speed(1))
	_btn_2x.pressed.connect(func() -> void: GameClock.set_speed(2))
	_btn_5x.pressed.connect(func() -> void: GameClock.set_speed(5))

	# Hiển thị trạng thái ban đầu
	_refresh_time(GameClock.day, GameClock.month, GameClock.year)
	_highlight_speed(GameClock.speed)

	_panel_info.hide()

func set_world_state(ws: WorldState) -> void:
	_world_state_ref = ws

func _process(_delta: float) -> void:
	if _tracked_citizen_id != -1 and _world_state_ref:
		_update_citizen_info()

func track_citizen(id: int) -> void:
	_tracked_citizen_id = id
	if id == -1:
		_panel_info.hide()
	else:
		_panel_info.show()
		_update_citizen_info()

func _update_citizen_info() -> void:
	var store := _world_state_ref.citizens
	var id := _tracked_citizen_id
	if store.alive[id] == 0:
		_panel_info.hide()
		_tracked_citizen_id = -1
		return

	var races := ["Người", "Tiên", "Orc", "Lùn"]
	var r := store.race_id[id]
	_label_title.text = "Cư dân #%d (%s)" % [id, races[r] if r < races.size() else "???"]
	_label_stats.text = "Tuổi: %d tháng\nĐói: %d/100\nHạnh phúc: %d/100" % [
		store.age[id],
		store.hunger[id],
		store.happiness[id]
	]

func _on_day_passed(day: int, month: int, year: int) -> void:
	_refresh_time(day, month, year)

func _on_speed_changed(new_speed: int) -> void:
	_highlight_speed(new_speed)

func _refresh_time(day: int, month: int, year: int) -> void:
	_label_time.text = "Ngày %d  Tháng %d  Năm %d" % [day, month, year]

func _highlight_speed(speed: int) -> void:
	# Reset tất cả nút về flat
	for btn: Button in [_btn_pause, _btn_1x, _btn_2x, _btn_5x]:
		btn.flat = false
		btn.modulate = Color(1.0, 1.0, 1.0, 0.6)
	# Nút đang chọn sáng lên
	match speed:
		0: _btn_pause.modulate = Color.WHITE
		1: _btn_1x.modulate    = Color.WHITE
		2: _btn_2x.modulate    = Color.WHITE
		5: _btn_5x.modulate    = Color.WHITE
