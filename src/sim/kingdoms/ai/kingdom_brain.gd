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
	
	var king_mask: int = 0
	if k.king_id != -1 and citizens.alive[k.king_id] == 1:
		king_mask = citizens.traits[k.king_id]
		
	var tax_amount: float = 1.0
	if TraitSystem.has_trait(king_mask, "greedy"): tax_amount = 2.0
	elif TraitSystem.has_trait(king_mask, "merchant"): tax_amount = 0.5
	
	# Chính sách linh hoạt theo ngân sách (Austerity / Prosperity)
	var is_bankrupt = false
	var is_prosperous = false
	if k.gold < 10.0:
		tax_amount = maxf(tax_amount, 3.0) # Khủng hoảng ngân sách -> Sưu cao thuế nặng!
		is_bankrupt = true
	elif k.gold > 100.0 and TraitSystem.has_trait(king_mask, "leader"):
		tax_amount = 0.0 # Quốc thái dân an, vua minh quân miễn thuế
		is_prosperous = true
	
	for cid: int in range(CitizenStore.MAX_CITIZENS):
		if citizens.alive[cid] == 1 and citizens.kingdom_id[cid] == k.id:
			pop += 1
			if citizens.job_id[cid] == -1:
				unemployed += 1
			else:
				if citizens.wealth[cid] >= tax_amount:
					citizens.wealth[cid] -= tax_amount
					k.gold += tax_amount
					if is_bankrupt:
						citizens.happiness[cid] = clampi(citizens.happiness[cid] - 3, 0, 100)
					elif tax_amount > 1.0: # Vua bóc lột -> giảm hạnh phúc
						citizens.happiness[cid] = clampi(citizens.happiness[cid] - 1, 0, 100)
					elif is_prosperous:
						citizens.happiness[cid] = clampi(citizens.happiness[cid] + 1, 0, 100)
			if citizens.home_id[cid] == -1:
				homeless += 1
				
	k.population = pop
	if pop == 0:
		return
		
	var res_mult: float = 1.0
	if TraitSystem.has_trait(king_mask, "smart") or TraitSystem.has_trait(king_mask, "genius"):
		res_mult = 1.2
		
	var grid = world.tile_grid
	for b_id in world.buildings:
		var b = world.buildings[b_id]
		if grid.in_bounds(b.x, b.y) and grid.owner_id[grid.idx(b.x, b.y)] == k.id:
			if b.workers_assigned > 0:
				if b.type == "farm": k.food += b.workers_assigned * 5.0 * res_mult
				elif b.type == "lumber_camp": k.wood += b.workers_assigned * 3.0 * res_mult
				elif b.type == "mine": k.stone += b.workers_assigned * 2.0 * res_mult
				elif b.type == "market": k.gold += b.workers_assigned * 2.0 * res_mult
	
	k.food = maxf(0.0, k.food - pop * 1.5)
		
	var ai_data: Dictionary = DataDB.ai()
	var p_data: Dictionary = ai_data.get("personalities", {}).get(k.personality, {})
	var w_housing: float = float(p_data.get("housing", 1.0))
	var w_infra: float = float(p_data.get("infrastructure", 1.0))
	var w_trade: float = float(p_data.get("trade", 1.0))
	
	if TraitSystem.has_trait(king_mask, "leader"):
		w_infra *= 1.5; w_trade *= 1.5
	if TraitSystem.has_trait(king_mask, "warrior") or TraitSystem.has_trait(king_mask, "aggressive"):
		w_infra *= 1.5; w_housing *= 0.5
	if TraitSystem.has_trait(king_mask, "lazy"):
		w_infra *= 0.5; w_trade *= 0.5
	
	var safe_food: float = float(pop) * 3.0
	if k.food < safe_food and k.gold >= 40:
		if CityPlanner.plan_farm(world, k, _rng):
			return # Đã làm 1 hành động

	# Nếu nhiều người thất nghiệp -> Xây công nghiệp/thương mại
	if unemployed > pop * (0.1 / w_trade) and k.gold >= 40:
		if CityPlanner.plan_job(world, k, _rng):
			return
			
	# Nếu thiếu đất trống -> Mở rộng lãnh thổ
	var grid: TileGrid = world.tile_grid
	var territory_size: int = CityPlanner._get_territory(grid, k.id).size()
	if territory_size < pop * 2.0 * w_infra and k.gold >= 50:
		if CityPlanner.plan_expansion(world, k, _rng):
			return
			
	# Nếu thiếu nhà ở -> Quy hoạch thêm vùng R
	if homeless > 0 or _rng.randf() < 0.1 * w_housing: # 10% mở rộng nhân hệ số
		if CityPlanner.plan_housing(world, k, _rng):
			return
