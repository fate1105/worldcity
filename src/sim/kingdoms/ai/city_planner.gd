class_name CityPlanner
extends RefCounted

## Người chịu trách nhiệm thực thi các chính sách của KingdomBrain thành Command cụ thể

static func plan_farm(world: WorldState, k: Kingdom, rng: RandomNumberGenerator) -> bool:
	return _try_place_bld(world, k, rng, "farm", TileGrid.ZoneType.I)

static func plan_job(world: WorldState, k: Kingdom, rng: RandomNumberGenerator) -> bool:
	if rng.randf() < 0.5:
		return _try_place_bld(world, k, rng, "market", TileGrid.ZoneType.C)
	else:
		return _try_place_bld(world, k, rng, "lumber_camp", TileGrid.ZoneType.I)

static func plan_housing(world: WorldState, k: Kingdom, rng: RandomNumberGenerator) -> bool:
	# Tìm một ô trống trong lãnh thổ để cắm mốc Zone R và xây đường
	var grid: TileGrid = world.tile_grid
	var candidates: Array[Vector2i] = _get_territory(grid, k.id)
	candidates.shuffle()
	
	for pos in candidates:
		var x: int = pos.x
		var y: int = pos.y
		var idx: int = grid.idx(x, y)
		if grid.building_id[idx] == -1 and grid.zone[idx] == TileGrid.ZoneType.NONE and grid.road[idx] == 0:
			if _is_buildable_terrain(grid.terrain[idx]):
				# Phải có đường bên cạnh, hoặc tự xây đường cạnh đó
				if not _has_adjacent_road(grid, x, y):
					if k.gold >= 2:
						# Xây đường ở một ô trống cạnh bên
						var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
						for d in dirs:
							var nx: int = x + d.x
							var ny: int = y + d.y
							if grid.in_bounds(nx, ny):
								var nidx: int = grid.idx(nx, ny)
								if grid.building_id[nidx] == -1 and grid.road[nidx] == 0 and _is_buildable_terrain(grid.terrain[nidx]):
									var road_cmd := PlaceRoadCommand.new(nx, ny, false)
									if CommandBus.submit(world, road_cmd) == OK:
										# Quy hoạch nhà ở x, y ngay lập tức
										var zcmd := SetZoneCommand.new(x, y, 0, TileGrid.ZoneType.R)
										CommandBus.submit(world, zcmd)
										return true
				else:
					# Đã có đường -> Quy hoạch
					var zone_cmd := SetZoneCommand.new(x, y, 0, TileGrid.ZoneType.R)
					if CommandBus.submit(world, zone_cmd) == OK:
						return true
	return false

static func plan_expansion(world: WorldState, k: Kingdom, rng: RandomNumberGenerator) -> bool:
	var grid: TileGrid = world.tile_grid
	var candidates: Array[Vector2i] = _get_territory(grid, k.id)
	candidates.shuffle()
	
	for pos in candidates:
		var x: int = pos.x
		var y: int = pos.y
		# Tìm một ô biên giới
		var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		for d in dirs:
			var nx: int = x + d.x
			var ny: int = y + d.y
			if grid.in_bounds(nx, ny):
				var idx: int = grid.idx(nx, ny)
				if grid.owner_id[idx] == -1:
					# Chiếm vùng nhỏ xung quanh
					k.gold -= 50
					for dy in range(-2, 3):
						for dx in range(-2, 3):
							var nnx = nx + dx
							var nny = ny + dy
							if grid.in_bounds(nnx, nny):
								var nidx: int = grid.idx(nnx, nny)
								if grid.owner_id[nidx] == -1:
									grid.owner_id[nidx] = k.id
									EventBus.tile_changed.emit(nnx, nny)
					return true
	return false

static func _try_place_bld(world: WorldState, k: Kingdom, rng: RandomNumberGenerator, btype: String, fallback_zone: int) -> bool:
	var grid: TileGrid = world.tile_grid
	var b_data: Dictionary = DataDB.building(btype)
	if b_data.is_empty(): return false
	
	var cost: float = float(b_data.get("cost", 0))
	if k.gold < cost: return false
	
	var candidates: Array[Vector2i] = _get_territory(grid, k.id)
	candidates.shuffle()
	
	for pos in candidates:
		var x: int = pos.x
		var y: int = pos.y
		var idx: int = grid.idx(x, y)
		
		# Phải trống
		var can_build: bool = true
		for dy in range(int(b_data.get("size", [1,1])[1])):
			for dx in range(int(b_data.get("size", [1,1])[0])):
				var nx: int = x + dx
				var ny: int = y + dy
				if not grid.in_bounds(nx, ny):
					can_build = false
					break
				var nidx: int = grid.idx(nx, ny)
				if grid.building_id[nidx] != -1 or grid.road[nidx] != 0 or not _is_buildable_terrain(grid.terrain[nidx]):
					can_build = false
					break
			if not can_build: break
			
		if can_build:
			# Đặt zone trước cho toàn bộ diện tích công trình
			for dy in range(int(b_data.get("size", [1,1])[1])):
				for dx in range(int(b_data.get("size", [1,1])[0])):
					var zcmd := SetZoneCommand.new(x + dx, y + dy, 0, fallback_zone)
					CommandBus.submit(world, zcmd)
			
			# Lệnh xây sẽ kiểm tra điều kiện terrain (grass cho farm, v.v.)
			var cmd := PlaceBuildingCommand.new(x, y, btype, world.next_building_id)
			if cmd.validate(world) == OK:
				CommandBus.submit(world, cmd)
				world.next_building_id += 1
				
				# Xây đường nối nếu chưa có
				if not _has_adjacent_road(grid, x, y) and k.gold >= 2:
					var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
					for d in dirs:
						var nx: int = x + d.x
						var ny: int = y + d.y
						if grid.in_bounds(nx, ny):
							var nidx: int = grid.idx(nx, ny)
							if grid.building_id[nidx] == -1 and grid.road[nidx] == 0 and _is_buildable_terrain(grid.terrain[nidx]):
								var r_cmd := PlaceRoadCommand.new(nx, ny, false)
								if CommandBus.submit(world, r_cmd) == OK:
									break
				return true
	return false

static func _get_territory(grid: TileGrid, k_id: int) -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	for y: int in range(grid.height):
		for x: int in range(grid.width):
			if grid.owner_id[grid.idx(x, y)] == k_id:
				arr.append(Vector2i(x, y))
	return arr

static func _is_buildable_terrain(t: int) -> bool:
	return t > 1 and t != 5 and t != 9

static func _has_adjacent_road(grid: TileGrid, x: int, y: int) -> bool:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for d in dirs:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if grid.in_bounds(nx, ny):
			if grid.road[grid.idx(nx, ny)] > 0:
				return true
	return false
