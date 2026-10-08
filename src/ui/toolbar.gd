class_name Toolbar
extends CanvasLayer

## Thanh công cụ dưới — Địa hình và Quyền năng
## Phát signal lên game.gd, không tự xử lý logic

## Signal phát khi người dùng chọn công cụ
signal terrain_selected(terrain_type: int)
signal power_selected(power_id: String)
signal spawn_selected(race_id: int)
signal brush_size_changed(size: int)
signal select_tool_selected()
signal road_tool_selected()

## Màu nút terrain (khớp WorldView.TILE_COLORS)
const TERRAIN_NAMES: Array[String] = [
	"Biển sâu", "Biển nông", "Cát", "Cỏ", "Rừng",
	"Núi", "Tuyết", "Sa mạc", "Đầm lầy", "Dung nham"
]
const TERRAIN_COLORS: Array[Color] = [
	Color(0.05, 0.15, 0.55),
	Color(0.15, 0.40, 0.80),
	Color(0.90, 0.85, 0.55),
	Color(0.35, 0.72, 0.25),
	Color(0.12, 0.42, 0.10),
	Color(0.50, 0.45, 0.40),
	Color(0.90, 0.95, 1.00),
	Color(0.88, 0.70, 0.30),
	Color(0.25, 0.45, 0.30),
	Color(0.95, 0.25, 0.05),
]
const POWER_LIST: Array[String]  = ["rain", "lightning", "fire", "volcano"]
const POWER_ICONS: Array[String] = ["🌧️", "⚡", "🔥", "🌋"]
const BRUSH_SIZES: Array[int]    = [1, 3, 5]

var _label_mana: Label
var _terrain_buttons: Array[Button] = []
var _power_buttons: Array[Button] = []
var _brush_buttons: Array[Button] = []
var _active_terrain: int = TileGrid.TileType.GRASS
var _active_brush: int = 1

@onready var _row_terrain: HBoxContainer = $BgPanel/VBox/RowTerrain
@onready var _row_power: HBoxContainer   = $BgPanel/VBox/RowPower
@onready var _row_spawn: HBoxContainer   = $BgPanel/VBox/RowSpawn

func _ready() -> void:
	_build_terrain_row()
	_build_power_row()
	_build_spawn_row()
	EventBus.mana_changed.connect(_on_mana_changed)

# ──────────────────────────────────────────────
# Xây UI theo code (tránh lỗi node path)
# ──────────────────────────────────────────────

func _build_terrain_row() -> void:
	# Nút Trỏ (Select)
	var btn_select := Button.new()
	btn_select.text = "Trỏ"
	btn_select.custom_minimum_size = Vector2(44, 36)
	btn_select.pressed.connect(func() -> void: select_tool_selected.emit())
	_row_terrain.add_child(btn_select)

	# Nút Đường (Road)
	var btn_road := Button.new()
	btn_road.text = "Đường"
	btn_road.custom_minimum_size = Vector2(60, 36)
	btn_road.pressed.connect(func() -> void: road_tool_selected.emit())
	_row_terrain.add_child(btn_road)

	# Label
	var lbl := Label.new()
	lbl.text = "Địa hình:"
	lbl.add_theme_font_size_override("font_size", 13)
	_row_terrain.add_child(lbl)

	# Nút terrain
	for i: int in range(TERRAIN_NAMES.size()):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(44, 36)
		btn.tooltip_text = TERRAIN_NAMES[i]
		# Màu nền cho nút
		var style := StyleBoxFlat.new()
		style.bg_color = TERRAIN_COLORS[i]
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style)
		var terrain_idx: int = i
		btn.pressed.connect(func() -> void: _on_terrain_pressed(terrain_idx))
		_row_terrain.add_child(btn)
		_terrain_buttons.append(btn)

	# Separator
	var sep := VSeparator.new()
	_row_terrain.add_child(sep)

	# Brush size
	var lbl_b := Label.new()
	lbl_b.text = "Cọ:"
	lbl_b.add_theme_font_size_override("font_size", 13)
	_row_terrain.add_child(lbl_b)

	for sz: int in BRUSH_SIZES:
		var btn := Button.new()
		btn.text = "%dx%d" % [sz, sz]
		btn.custom_minimum_size = Vector2(44, 36)
		var size_val: int = sz
		btn.pressed.connect(func() -> void: _on_brush_pressed(size_val))
		_row_terrain.add_child(btn)
		_brush_buttons.append(btn)

	_highlight_terrain(_active_terrain)
	_highlight_brush(_active_brush)

func _build_power_row() -> void:
	var lbl := Label.new()
	lbl.text = "Quyền năng:"
	lbl.add_theme_font_size_override("font_size", 13)
	_row_power.add_child(lbl)

	for i: int in range(POWER_LIST.size()):
		var btn := Button.new()
		var pid: String = POWER_LIST[i]
		var pdata: Dictionary = DataDB.power(pid)
		var mana_cost: int = int(pdata.get("mana", 0))
		btn.text = "%s %s\n[%d✦]" % [POWER_ICONS[i], pid.capitalize(), mana_cost]
		btn.custom_minimum_size = Vector2(80, 44)
		btn.add_theme_font_size_override("font_size", 12)
		var power_id: String = pid
		btn.pressed.connect(func() -> void: _on_power_pressed(power_id))
		_row_power.add_child(btn)
		_power_buttons.append(btn)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row_power.add_child(spacer)

	# Mana label
	_label_mana = Label.new()
	_label_mana.text = "✦ Mana: 100 / 100"
	_label_mana.add_theme_font_size_override("font_size", 14)
	_row_power.add_child(_label_mana)

func _build_spawn_row() -> void:
	var lbl := Label.new()
	lbl.text = "Sinh vật:"
	lbl.add_theme_font_size_override("font_size", 13)
	_row_spawn.add_child(lbl)

	var races := ["Người (Human)", "Tiên (Elf)", "Orc", "Người lùn (Dwarf)"]
	var colors := [Color.SKY_BLUE, Color.LIGHT_GREEN, Color.INDIAN_RED, Color.SANDY_BROWN]
	for i: int in range(races.size()):
		var btn := Button.new()
		btn.text = races[i]
		btn.custom_minimum_size = Vector2(100, 36)
		btn.add_theme_color_override("font_color", colors[i])
		var r_id: int = i
		btn.pressed.connect(func() -> void:
			spawn_selected.emit(r_id)
		)
		_row_spawn.add_child(btn)

# ──────────────────────────────────────────────
# Callbacks
# ──────────────────────────────────────────────

func _on_terrain_pressed(terrain_type: int) -> void:
	_active_terrain = terrain_type
	_highlight_terrain(terrain_type)
	terrain_selected.emit(terrain_type)

func _on_brush_pressed(size: int) -> void:
	_active_brush = size
	_highlight_brush(size)
	brush_size_changed.emit(size)

func _on_power_pressed(power_id: String) -> void:
	power_selected.emit(power_id)

func _on_mana_changed(current: float, maximum: float) -> void:
	if _label_mana:
		_label_mana.text = "✦ Mana: %d / %d" % [int(current), int(maximum)]

# ──────────────────────────────────────────────
# Highlight trạng thái nút đang chọn
# ──────────────────────────────────────────────

func _highlight_terrain(active: int) -> void:
	for i: int in range(_terrain_buttons.size()):
		_terrain_buttons[i].modulate = Color.WHITE if i == active else Color(1, 1, 1, 0.5)

func _highlight_brush(active: int) -> void:
	for i: int in range(_brush_buttons.size()):
		var is_active: bool = BRUSH_SIZES[i] == active
		_brush_buttons[i].modulate = Color.WHITE if is_active else Color(1, 1, 1, 0.6)
