class_name CitizenNames
extends RefCounted

## Quản lý tên cư dân theo chủng tộc.
## Mỗi cư dân có một name_id (int), tra cứu ra chuỗi tên đầy đủ.
## Không dùng Node. Không lưu tên trong PackedArray (tiết kiệm bộ nhớ).
const RACE_KEYS: Array[String] = ["human", "elf", "orc", "dwarf", "animal"]
# name_id → "First Last" (được xây lúc spawn, lưu trong Dictionary)
var _names: Dictionary = {}
var _next_name_id: int = 1

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

## Tạo tên ngẫu nhiên cho chủng tộc, trả về name_id
func generate(race_id: int) -> int:
	var race_key: String = RACE_KEYS[clampi(race_id, 0, RACE_KEYS.size() - 1)]
	var data: Dictionary = DataDB.name_list(race_key)
	if data.is_empty():
		_names[_next_name_id] = "Unknown"
		_next_name_id += 1
		return _next_name_id - 1

	var firsts: Array = data.get("first", ["Anon"])
	var lasts: Array  = data.get("last",  [""])
	var first: String = firsts[_rng.randi() % firsts.size()]
	var last: String  = lasts[_rng.randi() % lasts.size()]
	var full: String  = (first + " " + last).strip_edges()

	_names[_next_name_id] = full
	_next_name_id += 1
	return _next_name_id - 1

## Tra cứu tên đầy đủ từ name_id
func get_name(name_id: int) -> String:
	return _names.get(name_id, "???")
