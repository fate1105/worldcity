class_name EconomySystem
extends RefCounted

## Hệ thống kinh tế – gọi mỗi tháng.
## Công việc: gán dân vào nhà/việc, nông trại sản xuất thức ăn, thu thuế, trả upkeep, cập nhật ngân sách.
## Không dùng Node. Không sửa state trực tiếp ngoài các trường kinh tế.

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

## Gọi mỗi tháng game
func process_month(world_state: WorldState) -> void:
	_assign_jobs_and_homes(world_state)
	_produce_food(world_state)
	_collect_tax(world_state)
	_pay_upkeep(world_state)
	_feed_citizens(world_state)
	_update_budget_health(world_state)
	EventBus.economy_updated.emit(world_state.gold, world_state.food)

# ─────────────────────────────────────────────────
# 1. Gán nhà ở và việc làm cho dân chưa có
# ─────────────────────────────────────────────────
func _assign_jobs_and_homes(world_state: WorldState) -> void:
	var store: CitizenStore = world_state.citizens
	var buildings: Dictionary = world_state.buildings

	# Xây danh sách nhà có chỗ trống và nơi làm việc có chỗ
	for bld_id: int in buildings:
		var b: Building = buildings[bld_id]
		var bdata: Dictionary = DataDB.building(b.type)
		if bdata.is_empty():
			continue

		# --- Nhà ở (zone R) ---
		var capacity: int = int(bdata.get("capacity", 0))
		if capacity > 0:
			# Tìm dân vô gia cư để ở vào nhà này
			for cid: int in range(CitizenStore.MAX_CITIZENS):
				if store.alive[cid] == 0:
					continue
				if b.home_citizens.size() >= capacity:
					break
				if store.home_id[cid] == -1:
					store.home_id[cid] = bld_id
					b.home_citizens.append(cid)

		# --- Nơi làm việc (có trường workers) ---
		var max_workers: int = int(bdata.get("workers", 0))
		if max_workers > 0 and b.workers_assigned < max_workers:
			var needed: int = max_workers - b.workers_assigned
			for cid: int in range(CitizenStore.MAX_CITIZENS):
				if needed <= 0:
					break
				if store.alive[cid] == 0:
					continue
				if store.job_id[cid] == -1:
					store.job_id[cid] = bld_id
					b.workers_assigned += 1
					needed -= 1

# ─────────────────────────────────────────────────
# 2. Nông trại / lumber_camp / mine sản xuất tài nguyên
# ─────────────────────────────────────────────────
func _produce_food(world_state: WorldState) -> void:
	var buildings: Dictionary = world_state.buildings
	for bld_id: int in buildings:
		var b: Building = buildings[bld_id]
		var bdata: Dictionary = DataDB.building(b.type)
		if bdata.is_empty():
			continue
		var output: Dictionary = bdata.get("output", {})
		if output.is_empty():
			continue
		# Tỉ lệ: mỗi worker đóng góp (output / max_workers)
		var max_workers: int = int(bdata.get("workers", 1))
		var ratio: float = float(b.workers_assigned) / float(max(max_workers, 1))
		var grid_idx: int = world_state.tile_grid.idx(b.x, b.y)
		var k_id: int = world_state.tile_grid.owner_id[grid_idx]
		
		if k_id != -1 and world_state.kingdoms.has(k_id):
			var k: Kingdom = world_state.kingdoms[k_id]
			if output.has("food"): k.food += float(output["food"]) * ratio
			if output.has("wood"): k.wood += float(output["wood"]) * ratio
			if output.has("stone"): k.stone += float(output["stone"]) * ratio
		else:
			if output.has("food"): world_state.food += float(output["food"]) * ratio
			if output.has("wood"): world_state.wood += float(output["wood"]) * ratio
			if output.has("stone"): world_state.stone += float(output["stone"]) * ratio

# ─────────────────────────────────────────────────
# 3. Thu thuế từ nhà ở và thương mại
# ─────────────────────────────────────────────────
func _collect_tax(world_state: WorldState) -> void:
	var cfg_eco: Dictionary = DataDB.balance("economy")
	var tax_rate: float = float(cfg_eco.get("tax_default", 8)) / 100.0  # %
	var buildings: Dictionary = world_state.buildings
	var income: float = 0.0
	for bld_id: int in buildings:
		var b: Building = buildings[bld_id]
		var bdata: Dictionary = DataDB.building(b.type)
		if bdata.is_empty():
			continue
		# Nhà ở: thuế cố định * tỉ lệ lấp đầy; thương mại: cố định
		var base_tax: float = float(bdata.get("tax", 0))
		if base_tax > 0:
			var capacity: int = int(bdata.get("capacity", 1))
			var occupancy: float = float(b.home_citizens.size()) / float(max(capacity, 1))
		
		var grid_idx: int = world_state.tile_grid.idx(b.x, b.y)
		var k_id: int = world_state.tile_grid.owner_id[grid_idx]
		if k_id != -1 and world_state.kingdoms.has(k_id):
			var k: Kingdom = world_state.kingdoms[k_id]
			k.gold += income
		else:
			world_state.gold += income

# ─────────────────────────────────────────────────
# 4. Trả chi phí bảo trì công trình
# ─────────────────────────────────────────────────
func _pay_upkeep(world_state: WorldState) -> void:
	var buildings: Dictionary = world_state.buildings
	var total_upkeep: float = 0.0
	for bld_id: int in buildings:
		var b: Building = buildings[bld_id]
		if not b.active:
			continue
		var bdata: Dictionary = DataDB.building(b.type)
		if bdata.is_empty():
			continue
		var amount: float = float(bdata.get("upkeep", 0))
		var grid_idx: int = world_state.tile_grid.idx(b.x, b.y)
		var k_id: int = world_state.tile_grid.owner_id[grid_idx]
		if k_id != -1 and world_state.kingdoms.has(k_id):
			var k: Kingdom = world_state.kingdoms[k_id]
			k.gold -= amount
		else:
			world_state.gold -= amount

# ─────────────────────────────────────────────────
# 5. Tiêu thụ thức ăn (1 thức ăn / cư dân / tháng)
# ─────────────────────────────────────────────────
func _feed_citizens(world_state: WorldState) -> void:
	var store: CitizenStore = world_state.citizens
	var cfg: Dictionary = DataDB.balance("citizen")
	var food_per_month: float = float(cfg.get("food_per_month", 1))

	# Tính số thức ăn cần theo Kingdom
	var food_needed: Dictionary = {}
	for cid: int in range(CitizenStore.MAX_CITIZENS):
		if store.alive[cid] == 1:
			var k_id: int = store.kingdom_id[cid]
			if not food_needed.has(k_id):
				food_needed[k_id] = 0.0
			food_needed[k_id] += food_per_month
			
	for k_id: int in food_needed:
		var needed: float = food_needed[k_id]
		var k: Kingdom = world_state.kingdoms.get(k_id) if k_id != -1 else null
		var available: float = k.food if k else world_state.food
		var starving_chance: float = 0.0
		
		if available >= needed:
			if k: k.food -= needed
			else: world_state.food -= needed
		else:
			starving_chance = 1.0 - (available / maxf(needed, 1.0))
			if k: k.food = 0.0
			else:
				world_state.food = 0.0
				EventBus.food_shortage.emit(available, needed)

		# Áp dụng độ đói cho cư dân của k_id này
		for cid: int in range(CitizenStore.MAX_CITIZENS):
			if store.alive[cid] == 1 and store.kingdom_id[cid] == k_id:
				if starving_chance > 0.0:
					var extra_hunger: int = int(starving_chance * 30)
					store.hunger[cid] = clampi(int(store.hunger[cid]) + extra_hunger, 0, 100)
				else:
					store.hunger[cid] = 0

# ─────────────────────────────────────────────────
# 6. Cập nhật sức khỏe ngân sách
# ─────────────────────────────────────────────────
func _update_budget_health(world_state: WorldState) -> void:
	if world_state.gold < 0:
		world_state.deficit_months += 1
		var cfg: Dictionary = DataDB.balance("economy")
		var bankrupt_months: int = int(cfg.get("bankrupt_months", 3))
		if world_state.deficit_months >= bankrupt_months:
			EventBus.budget_crisis.emit(world_state.gold, world_state.deficit_months)
	else:
		world_state.deficit_months = 0
