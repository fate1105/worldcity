class_name CitySystem
extends RefCounted

## Quản lý các công trình (Buildings), quy hoạch (Zoning) và nhu cầu (Demand)

var _next_id: int = 1
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
	var b_data: Dictionary = DataDB.building(b_type)
	if b_data.is_empty():
		return false
	
	var size: Array = b_data.get("size", [1, 1])
	var bw: int = int(size[0])
	var bh: int = int(size[1])
	var grid: TileGrid = world_state.tile_grid
	
	# Kiểm tra vùng trống và cùng zone
	for dy in range(bh):
		for dx in range(bw):
			var nx: int = x + dx
			var ny: int = y + dy
			if not grid.in_bounds(nx, ny):
				return false
			var idx: int = grid.idx(nx, ny)
			if grid.building_id[idx] != -1 or grid.zone[idx] == TileGrid.ZoneType.NONE:
				return false
			if grid.terrain[idx] <= 1 or grid.terrain[idx] == 5 or grid.terrain[idx] == 9:
				return false
	
	# Xây dựng
	var b_id: int = _next_id
	_next_id += 1
	var building := Building.new(b_id, b_type, x, y, bw, bh)
	world_state.buildings[b_id] = building
	
	for dy in range(bh):
		for dx in range(bw):
			var idx: int = grid.idx(x + dx, y + dy)
			grid.building_id[idx] = b_id
	
	EventBus.building_placed.emit(b_id, x, y)
	
	# Đánh dấu thay đổi cho WorldView
	for dy in range(bh):
		for dx in range(bw):
			EventBus.tile_changed.emit(x + dx, y + dy)
			
	return true
