class_name CitizenSystem
extends RefCounted

## Xử lý logic của cư dân (AI đi lại, đói bụng, sinh lão bệnh tử, sinh sản)

enum AIState { IDLE, WANDER, WAITING_PATH, DEAD }

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

## Gọi mỗi tick (10 lần/giây)
func tick(world_state: WorldState, pathfinding: PathfindingSystem) -> void:
	var store: CitizenStore = world_state.citizens
	var grid: TileGrid = world_state.tile_grid
	var move_speed: float = 2.0  # units per tick (1 unit = 1 tile width)

	for id: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[id] == 0:
			continue

		var state: int = store.state[id]
		match state:
			AIState.IDLE:
				# Ngẫu nhiên đi loanh quanh
				if _rng.randf() < 0.05:
					# Tìm điểm đến gần đó (bán kính 5-10 ô)
					var dx: float = _rng.randf_range(-10.0, 10.0)
					var dy: float = _rng.randf_range(-10.0, 10.0)
					var nx: int = clampi(int(store.pos_x[id] + dx), 0, grid.width - 1)
					var ny: int = clampi(int(store.pos_y[id] + dy), 0, grid.height - 1)

					# Đảm bảo không bơi ra biển sâu/biển nông
					var t_idx: int = grid.idx(nx, ny)
					if grid.terrain[t_idx] > 1:
						pathfinding.request_path(id, Vector2i(int(store.pos_x[id]), int(store.pos_y[id])), Vector2i(nx, ny))
						store.state[id] = AIState.WAITING_PATH

			AIState.WANDER:
				var path: Array = store.paths[id]
				var p_idx: int = store.path_idx[id]
				if p_idx >= path.size():
					store.state[id] = AIState.IDLE
					continue

				var cx: float = store.pos_x[id]
				var cy: float = store.pos_y[id]
				var target: Vector2i = path[p_idx]
				var tx: float = target.x + 0.5
				var ty: float = target.y + 0.5

				var t_dx: float = tx - cx
				var t_dy: float = ty - cy
				var dist: float = sqrt(t_dx * t_dx + t_dy * t_dy)

				# Tốc độ đi tuỳ thuộc vào việc có đứng trên đường không
				var current_grid_idx: int = grid.idx(int(cx), int(cy))
				var is_on_road: bool = grid.road[current_grid_idx] > 0
				var actual_speed: float = move_speed * (2.0 if is_on_road else 1.0)

				if dist < 0.2:
					store.path_idx[id] += 1
				else:
					var vx: float = (t_dx / dist) * actual_speed * 0.1 # delta tĩnh
					var vy: float = (t_dy / dist) * actual_speed * 0.1
					store.pos_x[id] = cx + vx
					store.pos_y[id] = cy + vy

			AIState.WAITING_PATH:
				pass # PathfindingSystem sẽ tự gọi store.set_path() để đổi state sang WANDER hoặc IDLE

## Gọi mỗi ngày (100 tick)
func process_day(world_state: WorldState) -> void:
	var store: CitizenStore = world_state.citizens
	var config: Dictionary = DataDB.balance("citizen")
	var old_age_months: int = int(config.get("old_age", 60)) * 12 # old_age là năm, nhân 12 ra tháng
	var hunger_per_day: int = int(config.get("hunger_per_day", 1))

	for id: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[id] == 0:
			continue

		# Đói bụng
		store.hunger[id] = mini(store.hunger[id] + hunger_per_day, 100)
		
		# Cư dân tự do (chưa lập vương quốc) tự hái lượm thức ăn nếu đang đói
		if store.kingdom_id[id] == -1 and store.hunger[id] >= 30:
			var cx: int = int(store.pos_x[id])
			var cy: int = int(store.pos_y[id])
			if world_state.tile_grid.in_bounds(cx, cy):
				var t_idx: int = world_state.tile_grid.idx(cx, cy)
				var terrain: int = world_state.tile_grid.terrain[t_idx]
				if terrain == 3 or terrain == 4: # TileType.GRASS = 3, FOREST = 4
					store.hunger[id] = maxi(0, store.hunger[id] - 20)
		
		if store.hunger[id] >= 100:
			store.kill(id)
			continue

## Gọi mỗi tháng
func process_month(world_state: WorldState) -> void:
	var store: CitizenStore = world_state.citizens
	var cfg: Dictionary = DataDB.balance("citizen")
	# Lider race lifespan bằng năm, nhân 12 ra tháng
	# (mỗi cư dân dùng lifespan của chủng tộc riêng)

	for id: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[id] == 0:
			continue

		store.age[id] += 1

		# Tính lifespan theo chủng tộc
		var race_key: String = CitizenNames.RACE_KEYS[clampi(store.race_id[id], 0, CitizenNames.RACE_KEYS.size() - 1)]
		var rdata: Dictionary = DataDB.race(race_key)
		var lifespan_years: int = int(rdata.get("lifespan", 70))
		var lifespan_months: int = lifespan_years * 12

		# Trên tuổi thỏ: xác suất chết tăng dần (10 năm sau chắc chắn chết)
		if store.age[id] > lifespan_months:
			var over: int = store.age[id] - lifespan_months
			if _rng.randf() < float(over) / 120.0:
				store.kill(id)
				continue

	_process_reproduction(world_state)

## Sinh sản hàng tháng
func _process_reproduction(world_state: WorldState) -> void:
	var store: CitizenStore = world_state.citizens
	var cfg: Dictionary = DataDB.balance("citizen")
	var adult_age_months: int = int(cfg.get("adult_age", 15)) * 12
	var birth_happiness_min: int = int(cfg.get("birth_happiness_min", 50))

	# Thu thập danh sách người trưởng thành có cùng nhà
	# (key = home_id, value = array[citizen_id])
	var home_adults: Dictionary = {}
	for id: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[id] == 0:
			continue
		if store.age[id] < adult_age_months:
			continue
		if store.home_id[id] < 0:
			continue
		var hid: int = store.home_id[id]
		if not home_adults.has(hid):
			home_adults[hid] = []
		home_adults[hid].append(id)

	# Mỗi nhà có ít nhất 2 người: có khả năng sinh con
	for hid: int in home_adults:
		var adults: Array = home_adults[hid]
		if adults.size() < 2:
			continue
		var pa_id: int = adults[0]
		var pb_id: int = adults[1]
		# Điều kiện sinh: hạnh phúc cả hai > ngưỡng, không đói quá
		if store.happiness[pa_id] < birth_happiness_min:
			continue
		if store.happiness[pb_id] < birth_happiness_min:
			continue
		if store.hunger[pa_id] > 70 or store.hunger[pb_id] > 70:
			continue
		# Xác suất sinh theo birth_rate của chủng tộc
		var race_id: int = store.race_id[pa_id]
		var race_key: String = CitizenNames.RACE_KEYS[clampi(race_id, 0, CitizenNames.RACE_KEYS.size() - 1)]
		var rdata: Dictionary = DataDB.race(race_key)
		var birth_rate: float = float(rdata.get("birth_rate", 1.0)) * 0.1 # ~10%/tháng nhân hệ số
		if _rng.randf() > birth_rate:
			continue
		# Tạo con
		var child_traits: int = TraitSystem.inherit_traits(
			store.traits[pa_id], store.traits[pb_id], _rng)
		var child_nid: int = world_state.citizen_names.generate(race_id)
		var cx: float = store.pos_x[pa_id] + _rng.randf_range(-1.0, 1.0)
		var cy: float = store.pos_y[pa_id] + _rng.randf_range(-1.0, 1.0)
		var child_id: int = store.spawn_full(cx, cy, race_id, child_traits, child_nid, pa_id, pb_id, 0)
		if child_id >= 0:
			store.kingdom_id[child_id] = store.kingdom_id[pa_id]
			EventBus.citizen_born.emit(child_id, pa_id, pb_id)
