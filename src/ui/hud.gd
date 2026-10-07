extends CanvasLayer

## HUD chính — hiện thị thời gian và nút điều khiển tốc độ
## Nhận event từ EventBus, không đọc state trực tiếp mỗi frame

@onready var _label_time: Label     = $TopBar/HBoxTime/LabelTime
@onready var _btn_pause: Button     = $TopBar/HBoxSpeed/BtnPause
@onready var _btn_1x: Button        = $TopBar/HBoxSpeed/Btn1x
@onready var _btn_2x: Button        = $TopBar/HBoxSpeed/Btn2x
@onready var _btn_5x: Button        = $TopBar/HBoxSpeed/Btn5x

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
