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
var home_id: PackedInt32Array    # id Building (nhà ở), -1 = vô gia cư
var job_id: PackedInt32Array     # id Building (nơi làm), -1 = thất nghiệp

# M8 – chủng tộc, trait, gia phả
var traits: PackedInt32Array     # bitmask (xem TraitSystem)
var parent_a: PackedInt32Array   # id cư dân cha, -1 nếu không có
var parent_b: PackedInt32Array   # id cư dân mẹ
var name_id: PackedInt32Array    # tra trong CitizenNames

# Chỉ số cá nhân (0 - 100)
var stat_str: PackedByteArray    # Sức mạnh (Strength)
var stat_agi: PackedByteArray    # Nhanh nhẹn (Agility)
var stat_int: PackedByteArray    # Trí tuệ (Intelligence)
var stat_end: PackedByteArray    # Thể lực (Endurance)
var stat_cha: PackedByteArray    # Sức hút (Charisma)
var stat_crf: PackedByteArray    # Khéo léo (Craftsmanship)
var stat_lck: PackedByteArray    # May mắn (Luck)
var stat_brv: PackedByteArray    # Dũng cảm (Bravery)
var gender: PackedByteArray      # Giới tính (0: Nam, 1: Nữ)
var spouse_id: PackedInt32Array  # ID vợ/chồng (-1 là độc thân)
var wealth: PackedInt32Array     # Tiền bạc cá nhân
var action_desc: Array[String]   # Chuỗi mô tả hành động đang làm

var paths: Array                 # Array[Array[Vector2i]]
var path_idx: PackedInt32Array

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
	gender = PackedByteArray()
	gender.resize(MAX_CITIZENS)
	spouse_id = PackedInt32Array()
	spouse_id.resize(MAX_CITIZENS)
	spouse_id.fill(-1)
	wealth = PackedInt32Array()
	wealth.resize(MAX_CITIZENS)
	action_desc = []
	action_desc.resize(MAX_CITIZENS)
	home_id = PackedInt32Array()
	home_id.resize(MAX_CITIZENS)
	home_id.fill(-1)
	job_id = PackedInt32Array()
	job_id.resize(MAX_CITIZENS)
	job_id.fill(-1)

	traits = PackedInt32Array()
	traits.resize(MAX_CITIZENS)
	parent_a = PackedInt32Array()
	parent_a.resize(MAX_CITIZENS)
	parent_a.fill(-1)
	parent_b = PackedInt32Array()
	parent_b.resize(MAX_CITIZENS)
	parent_b.fill(-1)
	name_id = PackedInt32Array()
	name_id.resize(MAX_CITIZENS)
	
	stat_str = PackedByteArray(); stat_str.resize(MAX_CITIZENS)
	stat_agi = PackedByteArray(); stat_agi.resize(MAX_CITIZENS)
	stat_int = PackedByteArray(); stat_int.resize(MAX_CITIZENS)
	stat_end = PackedByteArray(); stat_end.resize(MAX_CITIZENS)
	stat_cha = PackedByteArray(); stat_cha.resize(MAX_CITIZENS)
	stat_crf = PackedByteArray(); stat_crf.resize(MAX_CITIZENS)
	stat_lck = PackedByteArray(); stat_lck.resize(MAX_CITIZENS)
	stat_brv = PackedByteArray(); stat_brv.resize(MAX_CITIZENS)

	paths = []
	paths.resize(MAX_CITIZENS)
	for i: int in range(MAX_CITIZENS):
		paths[i] = []
	path_idx = PackedInt32Array()
	path_idx.resize(MAX_CITIZENS)

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
	home_id[id] = -1
	job_id[id] = -1
	traits[id] = 0
	parent_a[id] = -1
	parent_b[id] = -1
	name_id[id] = 0
	paths[id] = []
	path_idx[id] = 0
	gender[id] = randi() % 2 # 0: Nam, 1: Nữ
	spouse_id[id] = -1
	wealth[id] = 0
	action_desc[id] = "Đang ngơ ngác"
	
	stat_str[id] = 50
	stat_agi[id] = 50
	stat_int[id] = 50
	stat_end[id] = 50
	stat_cha[id] = 50
	stat_crf[id] = 50
	stat_lck[id] = 50
	stat_brv[id] = 50

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

## Sinh cư dân đầy đủ (M8): có trait, tên, cha mẹ
## Dùng cho sinh sản và spawn quyền thần
func spawn_full(x: float, y: float, race: int, trait_mask: int,
		nid: int, pa: int = -1, pb: int = -1, start_age: int = 0, stats: Array[int] = []) -> int:
	var id: int = spawn(x, y, race)
	if id < 0:
		return -1
	traits[id]   = trait_mask
	name_id[id]  = nid
	parent_a[id] = pa
	parent_b[id] = pb
	age[id]      = start_age
	
	if stats.size() == 8:
		stat_str[id] = stats[0]
		stat_agi[id] = stats[1]
		stat_int[id] = stats[2]
		stat_end[id] = stats[3]
		stat_cha[id] = stats[4]
		stat_crf[id] = stats[5]
		stat_lck[id] = stats[6]
		stat_brv[id] = stats[7]
	# Áp happiness bonus từ trait
	happiness[id] = clampi(50 + TraitSystem.happiness_bonus(trait_mask), 0, 100)
	return id

func get_stats(id: int) -> Array[int]:
	return [
		stat_str[id], stat_agi[id], stat_int[id], stat_end[id],
		stat_cha[id], stat_crf[id], stat_lck[id], stat_brv[id]
	]

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

## Gắn đường đi cho công dân
func set_path(id: int, p: Array[Vector2i]) -> void:
	if id >= 0 and id < MAX_CITIZENS and alive[id] == 1:
		paths[id] = p
		path_idx[id] = 0
		# Nếu có đường đi, chuyển sang trạng thái WANDER (1)
		if p.size() > 0:
			state[id] = 1 # WANDER
		else:
			state[id] = 0 # IDLE
