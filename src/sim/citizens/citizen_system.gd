class_name CitizenSystem
extends RefCounted

## Xử lý logic của cư dân (AI đi lại, đói bụng, sinh lão bệnh tử)

enum AIState { IDLE, WANDER, DEAD }

var _rng: RandomNumberGenerator
var _dest_x: PackedFloat32Array
var _dest_y: PackedFloat32Array

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	_dest_x = PackedFloat32Array()
	_dest_y = PackedFloat32Array()
	_dest_x.resize(CitizenStore.MAX_CITIZENS)
	_dest_y.resize(CitizenStore.MAX_CITIZENS)

## Gọi mỗi tick (10 lần/giây)
func tick(world_state: WorldState) -> void:
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
					# Tìm điểm đến gần đó (bán kính 5 ô)
					var dx: float = _rng.randf_range(-5.0, 5.0)
					var dy: float = _rng.randf_range(-5.0, 5.0)
					var nx: float = clampf(store.pos_x[id] + dx, 0, grid.width - 1)
					var ny: float = clampf(store.pos_y[id] + dy, 0, grid.height - 1)

					# Đảm bảo không bơi ra biển sâu/biển nông
					var t_idx: int = grid.idx(int(nx), int(ny))
					if grid.terrain[t_idx] > 1:
						_dest_x[id] = nx
						_dest_y[id] = ny
						store.state[id] = AIState.WANDER

			AIState.WANDER:
				var cx: float = store.pos_x[id]
				var cy: float = store.pos_y[id]
				var tx: float = _dest_x[id]
				var ty: float = _dest_y[id]

				var dx: float = tx - cx
				var dy: float = ty - cy
				var dist: float = sqrt(dx * dx + dy * dy)

				if dist < 0.5:
					store.state[id] = AIState.IDLE
				else:
					var vx: float = (dx / dist) * move_speed * 0.1 # delta tĩnh
					var vy: float = (dy / dist) * move_speed * 0.1
					store.pos_x[id] = cx + vx
					store.pos_y[id] = cy + vy

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
