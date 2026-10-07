extends Node

## DataDB — autoload nạp toàn bộ JSON lúc khởi động
## Cung cấp hàm tra cứu nhanh, kiểm tra schema, báo lỗi rõ khi thiếu trường

var _buildings: Dictionary = {}
var _races: Dictionary = {}
var _traits: Dictionary = {}
var _powers: Dictionary = {}
var _disasters: Dictionary = {}
var _events: Dictionary = {}
var _terrain: Dictionary = {}
var _balance: Dictionary = {}

## Gọi 1 lần khi game khởi động (game.gd hoặc autoload _ready)
func load_all() -> void:
	_buildings = _load_json("res://data/buildings.json")
	_races      = _load_json("res://data/races.json")
	_traits     = _load_json("res://data/traits.json")
	_powers     = _load_json("res://data/powers.json")
	_disasters  = _load_json("res://data/disasters.json")
	_events     = _load_json("res://data/events.json")
	_terrain    = _load_json("res://data/terrain.json")
	_balance    = _load_json("res://data/balance.json")
	_validate_all()

# ──────────────────────────────────────────────
# Tra cứu
# ──────────────────────────────────────────────

func building(key: String) -> Dictionary:
	return _get(_buildings, "buildings", key)

func race(key: String) -> Dictionary:
	return _get(_races, "races", key)

func trait_data(key: String) -> Dictionary:
	return _get(_traits, "traits", key)

func power(key: String) -> Dictionary:
	return _get(_powers, "powers", key)

func disaster(key: String) -> Dictionary:
	return _get(_disasters, "disasters", key)

func terrain(key: String) -> Dictionary:
	return _get(_terrain, "terrain", key)

func balance(key: String) -> Variant:
	if _balance.has(key):
		return _balance[key]
	push_error("DataDB: thiếu balance key '%s'" % key)
	return null

func all_buildings() -> Dictionary:
	return _buildings

func all_races() -> Dictionary:
	return _races

func all_powers() -> Dictionary:
	return _powers

# ──────────────────────────────────────────────
# Nội bộ
# ──────────────────────────────────────────────

func _get(db: Dictionary, db_name: String, key: String) -> Dictionary:
	if db.has(key):
		return db[key] as Dictionary
	push_error("DataDB: không tìm thấy '%s' trong %s" % [key, db_name])
	return {}

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataDB: file không tồn tại: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataDB: không đọc được file: %s" % path)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(text)
	if result == null:
		push_error("DataDB: JSON không hợp lệ trong: %s" % path)
		return {}
	return result as Dictionary

func _validate_all() -> void:
	# Kiểm tra các trường bắt buộc của buildings
	for key: String in _buildings:
		var b: Dictionary = _buildings[key]
		if not b.has("cost"):
			push_error("DataDB: buildings['%s'] thiếu trường 'cost'" % key)
		if not b.has("upkeep"):
			push_error("DataDB: buildings['%s'] thiếu trường 'upkeep'" % key)

	# Kiểm tra races
	for key: String in _races:
		var r: Dictionary = _races[key]
		for field: String in ["lifespan", "birth_rate", "attack", "color"]:
			if not r.has(field):
				push_error("DataDB: races['%s'] thiếu trường '%s'" % [key, field])

	# Kiểm tra powers
	for key: String in _powers:
		var p: Dictionary = _powers[key]
		if not p.has("mana"):
			push_error("DataDB: powers['%s'] thiếu trường 'mana'" % key)
