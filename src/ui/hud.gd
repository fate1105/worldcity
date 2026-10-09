extends CanvasLayer

## HUD chính — hiện thị thời gian và nút điều khiển tốc độ
## Nhận event từ EventBus, không đọc state trực tiếp mỗi frame

@onready var _label_time: Label     = $TopBar/HBoxMain/HBoxTime/LabelTime
@onready var _btn_pause: Button     = $TopBar/HBoxMain/HBoxSpeed/BtnPause
@onready var _btn_1x: Button        = $TopBar/HBoxMain/HBoxSpeed/Btn1x
@onready var _btn_2x: Button        = $TopBar/HBoxMain/HBoxSpeed/Btn2x
@onready var _btn_5x: Button        = $TopBar/HBoxMain/HBoxSpeed/Btn5x
@onready var _label_economy: Label  = $TopBar/HBoxMain/LabelEconomy

@onready var _panel_info: PanelContainer = $PanelInfo
@onready var _label_title: Label         = $PanelInfo/VBox/LabelTitle
@onready var _label_stats: Label         = $PanelInfo/VBox/LabelStats
@onready var _tex_minimap: TextureRect   = $PanelMinimap/TextureRect

var _tracked_citizen_id: int = -1
var _world_state_ref: WorldState

func _ready() -> void:
	# Kết nối signal từ EventBus
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.speed_changed.connect(_on_speed_changed)
	EventBus.economy_updated.connect(_on_economy_updated)

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
	var citizen_name := _world_state_ref.citizen_names.get_name(store.name_id[id])
	var trait_mask := store.traits[id]
	var trait_list := TraitSystem.get_trait_keys(trait_mask)
	var trait_str := "Không" if trait_list.is_empty() else ", ".join(trait_list)

	var k_id: int = store.kingdom_id[id]
	var kingdom_str: String = "Tự do"
	if k_id != -1 and _world_state_ref.kingdoms.has(k_id):
		var k: Kingdom = _world_state_ref.kingdoms[k_id]
		kingdom_str = "%s (Vàng: %d | Thực: %d | Gỗ: %d | Đá: %d)" % [k.name, int(k.gold), int(k.food), int(k.wood), int(k.stone)]

	_label_title.text = "%s (%s)" % [citizen_name, races[r] if r < races.size() else "???"]
	_label_stats.text = "Vương quốc: %s\nTuổi: %d tháng\nĐói: %d/100\nHạnh phúc: %d/100\nTraits: %s" % [
		kingdom_str,
		store.age[id],
		store.hunger[id],
		store.happiness[id],
		trait_str
	]

func _on_day_passed(day: int, month: int, year: int) -> void:
	_refresh_time(day, month, year)
	_update_top_bar()
	_update_minimap()

func _update_minimap() -> void:
	if not _world_state_ref:
		return
	var grid := _world_state_ref.tile_grid
	var w: int = grid.width
	var h: int = grid.height
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	
	for y: int in range(h):
		for x: int in range(w):
			var idx: int = grid.idx(x, y)
			var terrain: int = grid.terrain[idx]
			# Màu cơ bản (tương đối)
			var color: Color = Color(0.2, 0.4, 0.2) if terrain >= 3 and terrain <= 4 else Color(0.1, 0.3, 0.6)
			if terrain == 2: color = Color(0.8, 0.8, 0.4)
			elif terrain == 5: color = Color(0.5, 0.5, 0.5)
			elif terrain == 6: color = Color(0.9, 0.9, 0.9)
			
			var o_id: int = grid.owner_id[idx]
			if o_id != -1 and _world_state_ref.kingdoms.has(o_id):
				var k: Kingdom = _world_state_ref.kingdoms[o_id]
				color = k.color
				
			img.set_pixel(x, y, color)
			
	var tex := ImageTexture.create_from_image(img)
	_tex_minimap.texture = tex

func _on_economy_updated(_gold: float, _food: float) -> void:
	pass # Bỏ qua cái này vì sẽ update chung ở _on_day_passed

func _update_top_bar() -> void:
	if not _world_state_ref: return
	
	var pop: int = 0
	var store: CitizenStore = _world_state_ref.citizens
	for id: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[id] == 1:
			pop += 1
			
	var k_count: int = _world_state_ref.kingdoms.size()
	var g_gold: int = int(_world_state_ref.gold)
	var g_food: int = int(_world_state_ref.food)
	
	_label_economy.text = "God: 🪙 %d 🍖 %d  |  Dân số: %d  |  Vương quốc: %d" % [g_gold, g_food, pop, k_count]

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
