class_name KingdomSystem
extends RefCounted

var _rng: RandomNumberGenerator
var _brain: KingdomBrain

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	_brain = KingdomBrain.new(rng)

## Gọi mỗi tháng để xử lý logic vương quốc (AI thành lập)
func process_month(world: WorldState) -> void:
	_try_found_kingdom(world)
	
	# Chạy não bộ AI cho từng vương quốc
	for k_id: int in world.kingdoms:
		var k: Kingdom = world.kingdoms[k_id]
		_brain.process_month(world, k)

func _try_found_kingdom(world: WorldState) -> void:
	var cfg: Dictionary = DataDB.balance("kingdom")
	var min_pop: int = int(cfg.get("found_min_population", 2))
	var radius: int = int(cfg.get("initial_radius", 5))

	var citizens: CitizenStore = world.citizens
	var free_cids: Array[int] = []
	
	for cid: int in range(CitizenStore.MAX_CITIZENS):
		if citizens.alive[cid] == 1 and citizens.kingdom_id[cid] == -1:
			free_cids.append(cid)
			
	if free_cids.size() < min_pop:
		return
		
	# Tìm cụm người
	for i in range(free_cids.size()):
		var root_cid: int = free_cids[i]
		if citizens.kingdom_id[root_cid] != -1: continue
		
		var cx: float = citizens.pos_x[root_cid]
		var cy: float = citizens.pos_y[root_cid]
		
		var cluster: Array[int] = [root_cid]
		for j in range(i + 1, free_cids.size()):
			var other_cid: int = free_cids[j]
			var dx: float = citizens.pos_x[other_cid] - cx
			var dy: float = citizens.pos_y[other_cid] - cy
			if dx*dx + dy*dy < 400.0: # Cách nhau < 20 ô
				cluster.append(other_cid)
				
		if cluster.size() >= min_pop:
			var int_cx: int = int(cx)
			var int_cy: int = int(cy)
			if not world.tile_grid.in_bounds(int_cx, int_cy): continue
			var idx: int = world.tile_grid.idx(int_cx, int_cy)
			if world.tile_grid.owner_id[idx] != -1: continue
			
			var race_id: int = citizens.race_id[root_cid]
			var race_key: String = CitizenNames.RACE_KEYS[clampi(race_id, 0, CitizenNames.RACE_KEYS.size() - 1)]
			var k_id: int = world.next_kingdom_id
			world.next_kingdom_id += 1
			
			var k_name: String = "Vương quốc " + world.citizen_names.get_name(world.citizen_names.generate(race_id))
			var rdata: Dictionary = DataDB.race(race_key)
			var color_str: String = rdata.get("color", "#ffffff")
			var k_color: Color = Color(color_str)
			
			var k := Kingdom.new(k_id, k_name, race_id, k_color, -1, world.year)
			k.gold = 500
			k.food = 100
			k.wood = 100
			k.stone = 50
			
			world.kingdoms[k_id] = k
			_claim_territory(world, int_cx, int_cy, radius, k_id)
			
			for cid in cluster:
				citizens.kingdom_id[cid] = k_id
				
			EventBus.kingdom_founded.emit(k_id, int_cx, int_cy)
			return # Chỉ lập 1 vương quốc mỗi tháng để tránh lag

func _claim_territory(world: WorldState, cx: int, cy: int, radius: int, k_id: int) -> void:
	var grid: TileGrid = world.tile_grid
	var r2: int = radius * radius
	
	for y: int in range(max(0, cy - radius), min(world.map_height, cy + radius + 1)):
		for x: int in range(max(0, cx - radius), min(world.map_width, cx + radius + 1)):
			var dx: int = x - cx
			var dy: int = y - cy
			if dx * dx + dy * dy <= r2:
				var idx: int = grid.idx(x, y)
				if grid.owner_id[idx] == -1:
					grid.owner_id[idx] = k_id
					EventBus.tile_changed.emit(x, y)
	
	# Gán kingdom_id cho công dân đang đứng trong vùng mới chiếm
	var citizens: CitizenStore = world.citizens
	for cid: int in range(CitizenStore.MAX_CITIZENS):
		if citizens.alive[cid] == 1 and citizens.kingdom_id[cid] == -1:
			var idx: int = grid.idx(int(citizens.pos_x[cid]), int(citizens.pos_y[cid]))
			if grid.owner_id[idx] == k_id:
				citizens.kingdom_id[cid] = k_id
