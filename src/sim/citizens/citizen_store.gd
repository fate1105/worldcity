class_name CitizenStore
extends RefCounted

## Lưu trữ cư dân theo mô hình SoA (Structure of Arrays) để tối ưu cache và tránh overhead
## Mỗi cư dân được định danh bằng một số nguyên (index).

const MAX_CITIZENS: int = 16384

var count: int = 0
var alive: PackedByteArray
var pos_x: PackedFloat32Array
var pos_y: PackedFloat32Array
var age: PackedInt32Array        # tính theo tick hoặc tháng
var hunger: PackedByteArray      # 0 - 100
var happiness: PackedByteArray   # 0 - 100
var race_id: PackedByteArray     # map sang DataDB (0: human, 1: elf...)
var kingdom_id: PackedInt32Array
var state: PackedByteArray       # AIState

var _free_list: PackedInt32Array

func _init() -> void:
	alive = PackedByteArray()
	alive.resize(MAX_CITIZENS)
	pos_x = PackedFloat32Array()
	pos_x.resize(MAX_CITIZENS)
	pos_y = PackedFloat32Array()
	pos_y.resize(MAX_CITIZENS)
	age = PackedInt32Array()
	age.resize(MAX_CITIZENS)
	hunger = PackedByteArray()
	hunger.resize(MAX_CITIZENS)
	happiness = PackedByteArray()
	happiness.resize(MAX_CITIZENS)
	race_id = PackedByteArray()
	race_id.resize(MAX_CITIZENS)
	kingdom_id = PackedInt32Array()
	kingdom_id.resize(MAX_CITIZENS)
	state = PackedByteArray()
	state.resize(MAX_CITIZENS)

	_free_list = PackedInt32Array()
	# Điền free list từ N-1 về 0 để pop ra từ cuối
	for i: int in range(MAX_CITIZENS - 1, -1, -1):
		_free_list.push_back(i)

## Cấp phát 1 ID cư dân mới
func spawn(x: float, y: float, race: int) -> int:
	if _free_list.is_empty():
		push_error("CitizenStore: Hết chỗ chứa cư dân (MAX = %d)" % MAX_CITIZENS)
		return -1

	var id: int = _free_list[ _free_list.size() - 1 ]
	_free_list.remove_at(_free_list.size() - 1)

	alive[id] = 1
	pos_x[id] = x
	pos_y[id] = y
	age[id] = 0
	hunger[id] = 0
	happiness[id] = 50
	race_id[id] = race
	kingdom_id[id] = -1
	state[id] = 0 # IDLE

	count += 1
	EventBus.citizen_spawned.emit(id)
	return id

## Tiêu diệt cư dân
func kill(id: int) -> void:
	if id < 0 or id >= MAX_CITIZENS or alive[id] == 0:
		return
	alive[id] = 0
	count -= 1
	_free_list.push_back(id)
	EventBus.citizen_died.emit(id)

## Tìm cư dân gần nhất (click chuột)
func get_closest(x: float, y: float, max_dist: float = 2.0) -> int:
	var best_id: int = -1
	var best_dist2: float = max_dist * max_dist
	for id: int in range(MAX_CITIZENS):
		if alive[id] == 1:
			var dx: float = pos_x[id] - x
			var dy: float = pos_y[id] - y
			var dist2: float = dx * dx + dy * dy
			if dist2 < best_dist2:
				best_dist2 = dist2
				best_id = id
	return best_id
