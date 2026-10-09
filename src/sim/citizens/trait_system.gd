class_name TraitSystem
extends RefCounted

## Hệ thống trait – đọc từ traits.json, áp modifier lên cư dân.
## Trait lưu dạng bitmask int32 trong CitizenStore.traits[id].
## Tối đa 30 trait (bit 0-29). Danh sách thứ tự cố định theo TRAIT_KEYS.

const TRAIT_KEYS: Array[String] = [
	"hardworking", "smart", "brave", "healthy", "lucky", "leader",  # bits 0-5 (good)
	"lazy", "coward", "sickly", "greedy", "aggressive", "unlucky",  # bits 6-11 (bad)
	"mutated", "cursed", "blessed", "immortal"                       # bits 12-15 (special)
]
const MAX_TRAITS_PER_CITIZEN: int = 3

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

## Sinh trait ngẫu nhiên khi spawn (0-2 traits)
static func random_spawn_traits(rng: RandomNumberGenerator) -> int:
	var mask: int = 0
	var n: int = rng.randi_range(0, 2)
	var available: Array[String] = TRAIT_KEYS.duplicate()
	for _i: int in range(n):
		if available.is_empty():
			break
		var idx: int = rng.randi() % available.size()
		mask = add_trait(mask, available[idx])
		available.remove_at(idx)
	return mask

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
