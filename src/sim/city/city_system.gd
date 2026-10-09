class_name CitySystem
extends RefCounted

## Quản lý các công trình (Buildings), quy hoạch (Zoning) và nhu cầu (Demand)

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

## Gọi mỗi ngày để mô phỏng phát triển đô thị (nhà tự mọc)
func process_day(world_state: WorldState) -> void:
	_grow_buildings(world_state)

func _grow_buildings(world_state: WorldState) -> void:
	var grid: TileGrid = world_state.tile_grid
	# Lấy ngẫu nhiên vài ô để thử xây nhà (tránh duyệt toàn bản đồ mỗi ngày gây lag)
	var checks: int = 100
	for i in range(checks):
		var x: int = _rng.randi_range(0, grid.width - 1)
		var y: int = _rng.randi_range(0, grid.height - 1)
		var idx: int = grid.idx(x, y)
		
		var z: int = grid.zone[idx]
		if z == TileGrid.ZoneType.NONE or grid.building_id[idx] != -1:
			continue # Ô không được quy hoạch hoặc đã có nhà
		
		if grid.terrain[idx] <= 1 or grid.terrain[idx] == 5 or grid.terrain[idx] == 9:
			continue # Không xây trên biển, núi, dung nham
		
		# Thử xây nhà theo zone
		if z == TileGrid.ZoneType.R:
			_try_place_building(world_state, x, y, "house_1")
		elif z == TileGrid.ZoneType.C:
			_try_place_building(world_state, x, y, "market")
		elif z == TileGrid.ZoneType.I:
			_try_place_building(world_state, x, y, "farm")

func _try_place_building(world_state: WorldState, x: int, y: int, b_type: String) -> bool:
	var cmd := PlaceBuildingCommand.new(x, y, b_type, world_state.next_building_id)
	if CommandBus.submit(world_state, cmd) == OK:
		world_state.next_building_id += 1
		return true
	return false
