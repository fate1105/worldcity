class_name CitySystem
extends RefCounted

## Quản lý các công trình (Buildings), quy hoạch (Zoning) và nhu cầu (Demand)

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

## Gọi mỗi ngày để mô phỏng phát triển đô thị (nhà tự mọc)
func process_day(world_state: WorldState) -> void:
	pass
