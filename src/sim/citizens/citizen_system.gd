class_name CitizenSystem
extends RefCounted

## Xử lý logic của cư dân (AI đi lại, đói bụng, sinh lão bệnh tử)

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
	var hunger_per_day: int = int(config.get("hunger_per_day", 5))

	for id: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[id] == 0:
			continue

		# Đói bụng
		store.hunger[id] = mini(store.hunger[id] + hunger_per_day, 100)
		if store.hunger[id] >= 100:
			store.kill(id)
			continue

## Gọi mỗi tháng
func process_month(world_state: WorldState) -> void:
	var store: CitizenStore = world_state.citizens
	var config: Dictionary = DataDB.balance("citizen")
	var old_age_months: int = int(config.get("old_age", 60)) * 12

	for id: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[id] == 0:
			continue

		store.age[id] += 1
		# Già chết (tuổi tác ngẫu nhiên sau khi vượt qua old_age)
		if store.age[id] > old_age_months:
			var over_age: int = store.age[id] - old_age_months
			if _rng.randf() < (float(over_age) / 120.0): # 10 năm sau old_age chắc chắn chết
				store.kill(id)
