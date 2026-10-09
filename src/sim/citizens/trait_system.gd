class_name TraitSystem
extends RefCounted

## Hệ thống trait – đọc từ traits.json, áp modifier lên cư dân.
## Trait lưu dạng bitmask int32 trong CitizenStore.traits[id].
## Tối đa 30 trait (bit 0-29). Danh sách thứ tự cố định theo TRAIT_KEYS.

const TRAIT_KEYS: Array[String] = [
	# Cơ bản (Good)
	"hardworking", "smart", "brave", "healthy", "lucky", "leader",
	# Cơ bản (Bad)
	"lazy", "coward", "sickly", "greedy", "aggressive", "unlucky",
	# Nâng cao (Cần nhiều chỉ số)
	"warrior", "genius", "assassin", "merchant", "craftsman", "giant",
	# Đặc biệt
	"mutated", "cursed", "blessed", "immortal"
]
const MAX_TRAITS_PER_CITIZEN: int = 4

## Trả về bitmask của 1 trait key
static func bit(key: String) -> int:
	var idx: int = TRAIT_KEYS.find(key)
	if idx < 0:
		return 0
	return 1 << idx

## Kiểm tra cư dân có trait không
static func has_trait(mask: int, key: String) -> bool:
	return (mask & bit(key)) != 0

## Thêm trait vào mask
static func add_trait(mask: int, key: String) -> int:
	return mask | bit(key)

## Xóa trait
static func remove_trait(mask: int, key: String) -> int:
	return mask & ~bit(key)

## Lấy danh sách key của các trait cư dân đang có
static func get_trait_keys(mask: int) -> Array[String]:
	var result: Array[String] = []
	for i: int in range(TRAIT_KEYS.size()):
		if (mask & (1 << i)) != 0:
			result.append(TRAIT_KEYS[i])
	return result

## Đếm số trait đang có
static func count(mask: int) -> int:
	var n: int = 0
	for i: int in range(TRAIT_KEYS.size()):
		if (mask & (1 << i)) != 0:
			n += 1
	return n

## Sinh trait dựa trên chỉ số (M8)
static func generate_traits_from_stats(stats: Array[int], rng: RandomNumberGenerator) -> int:
	var mask: int = 0
	if stats.is_empty() or stats.size() < 8: return 0
	
	var st_str = stats[0]; var st_agi = stats[1]; var st_int = stats[2]; var st_end = stats[3]
	var st_cha = stats[4]; var st_crf = stats[5]; var st_lck = stats[6]; var st_brv = stats[7]
	
	var possible: Array[String] = []
	# Traits nâng cao (Cần nhiều chỉ số)
	if st_str >= 85 and st_brv >= 85 and st_end >= 75: possible.append("warrior")
	if st_int >= 90 and st_lck >= 75 and st_crf >= 70: possible.append("genius")
	if st_agi >= 90 and st_str >= 75 and st_int >= 75: possible.append("assassin")
	if st_cha >= 85 and st_int >= 85 and st_lck >= 60: possible.append("merchant")
	if st_crf >= 90 and st_str >= 80 and st_end >= 70: possible.append("craftsman")
	if st_str >= 95 and st_end >= 95 and st_agi <= 40: possible.append("giant")
	
	# Traits cơ bản
	if st_crf >= 75 and st_end >= 60: possible.append("hardworking")
	if st_int >= 80: possible.append("smart")
	if st_brv >= 80: possible.append("brave")
	if st_end >= 80: possible.append("healthy")
	if st_lck >= 80: possible.append("lucky")
	if st_cha >= 80 and st_int >= 70: possible.append("leader")
	
	if st_agi <= 30 and st_end <= 40: possible.append("lazy")
	if st_brv <= 30: possible.append("coward")
	if st_end <= 30: possible.append("sickly")
	if st_cha <= 30: possible.append("greedy")
	if st_str >= 75 and st_int <= 45: possible.append("aggressive")
	if st_lck <= 30: possible.append("unlucky")
	
	if rng.randf() < 0.01: possible.append("mutated")
	if rng.randf() < 0.005: possible.append("blessed")
	if rng.randf() < 0.005: possible.append("cursed")
	
	possible.shuffle()
	var n: int = rng.randi_range(1, 3)
	for i in range(min(possible.size(), n + 1)):
		mask = add_trait(mask, possible[i])
	return mask

## Sinh 8 chỉ số ngẫu nhiên (M8)
static func generate_random_stats(rng: RandomNumberGenerator) -> Array[int]:
	return [
		rng.randi_range(1, 100), # Sức mạnh
		rng.randi_range(1, 100), # Nhanh nhẹn
		rng.randi_range(1, 100), # Trí tuệ
		rng.randi_range(1, 100), # Thể lực
		rng.randi_range(1, 100), # Sức hút
		rng.randi_range(1, 100), # Khéo léo
		rng.randi_range(1, 100), # May mắn
		rng.randi_range(1, 100)  # Dũng cảm
	]

## Di truyền chỉ số từ cha mẹ
static func inherit_stats(rng: RandomNumberGenerator, a_stats: Array[int], b_stats: Array[int]) -> Array[int]:
	var child: Array[int] = []
	for i in range(8):
		var base: int = (a_stats[i] + b_stats[i]) / 2
		var mutation: int = rng.randi_range(-10, 10)
		child.append(clampi(base + mutation, 1, 100))
	return child

## Thừa hưởng trait từ cha mẹ (30% mỗi trait của cha/mẹ, tối đa 3 traits)
static func inherit_traits(mask_a: int, mask_b: int, rng: RandomNumberGenerator,
		inherit_chance: float = 0.30) -> int:
	var mask: int = 0
	var cfg: Dictionary = DataDB.balance("citizen")
	var chance: float = float(cfg.get("trait_inherit", inherit_chance))
	for i: int in range(TRAIT_KEYS.size()):
		if count(mask) >= MAX_TRAITS_PER_CITIZEN:
			break
		var from_a: bool = (mask_a & (1 << i)) != 0
		var from_b: bool = (mask_b & (1 << i)) != 0
		if (from_a or from_b) and rng.randf() < chance:
			mask |= (1 << i)
	# Nhỏ xác suất đột biến
	if rng.randf() < 0.02 and count(mask) < MAX_TRAITS_PER_CITIZEN:
		mask = add_trait(mask, "mutated")
	return mask

## Lấy modifier tổng hợp cho work output
static func work_modifier(mask: int) -> float:
	var mod: float = 1.0
	for key: String in get_trait_keys(mask):
		var tdata: Dictionary = DataDB.trait_data(key)
		mod += float(tdata.get("work_mod", 0.0))
	return maxf(mod, 0.1)

## Lấy modifier happiness (cộng thêm, không nhân)
static func happiness_bonus(mask: int) -> int:
	var bonus: int = 0
	for key: String in get_trait_keys(mask):
		var tdata: Dictionary = DataDB.trait_data(key)
		bonus += int(tdata.get("happiness_mod", 0))
	return bonus
