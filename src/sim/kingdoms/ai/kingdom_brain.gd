class_name KingdomBrain
extends RefCounted

## Bộ não quản lý Vương quốc (Quyết định xây gì, mở rộng thế nào)

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

func process_month(world: WorldState, k: Kingdom) -> void:
	# Cân nhắc 1-2 hành động mỗi tháng
	var actions: int = 1
	for i in range(actions):
		_think(world, k)

func _think(world: WorldState, k: Kingdom) -> void:
	# Đánh giá nhu cầu:
	# 1. Thực phẩm (nếu thiếu -> xây farm)
	var citizens: CitizenStore = world.citizens
	var pop: int = 0
	var unemployed: int = 0
	var homeless: int = 0
	
	for cid: int in range(CitizenStore.MAX_CITIZENS):
		if citizens.alive[cid] == 1 and citizens.kingdom_id[cid] == k.id:
			pop += 1
			if citizens.job_id[cid] == -1:
				unemployed += 1
			if citizens.home_id[cid] == -1:
				homeless += 1
				
	k.population = pop
	if pop == 0:
		return
		
	# Nếu thức ăn dự trữ không đủ cho 3 tháng tới -> Xây farm
	var safe_food: float = float(pop) * 3.0
	if k.food < safe_food and k.gold >= 40:
		if CityPlanner.plan_farm(world, k, _rng):
			return # Đã làm 1 hành động

	# Nếu nhiều người thất nghiệp -> Xây công nghiệp/thương mại
	if unemployed > pop * 0.1 and k.gold >= 40:
		if CityPlanner.plan_job(world, k, _rng):
			return
			
	# Nếu thiếu đất trống -> Mở rộng lãnh thổ
	var grid: TileGrid = world.tile_grid
	var territory_size: int = CityPlanner._get_territory(grid, k.id).size()
	if territory_size < pop * 2 and k.gold >= 50:
		if CityPlanner.plan_expansion(world, k, _rng):
			return
			
	# Nếu thiếu nhà ở -> Quy hoạch thêm vùng R
	if homeless > 0 or _rng.randf() < 0.1: # 10% mở rộng
		if CityPlanner.plan_housing(world, k, _rng):
			return
