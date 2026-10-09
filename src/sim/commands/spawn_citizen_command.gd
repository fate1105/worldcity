class_name SpawnCitizenCommand
extends Command

var tx: int
var ty: int
var race_id: int

func _init(x: int, y: int, r_id: int) -> void:
	tx = x
	ty = y
	race_id = r_id

func validate(state: WorldState) -> Error:
	var grid: TileGrid = state.tile_grid
	if not grid.in_bounds(tx, ty): return FAILED
	var t: int = grid.terrain[grid.idx(tx, ty)]
	if t <= 1: return FAILED # Không đẻ dưới nước
	return OK

func execute(state: WorldState) -> void:
	# Sinh trait ngẫu nhiên dựa trên chỉ số
	var stats: Array[int] = TraitSystem.generate_random_stats(state.rng)
	var trait_mask: int = TraitSystem.generate_traits_from_stats(stats, state.rng)
	var nid: int = state.citizen_names.generate(race_id)
	state.citizens.spawn_full(float(tx) + 0.5, float(ty) + 0.5, race_id, trait_mask, nid, -1, -1, 0, stats)

func describe() -> String:
	return "Spawn Citizen %d at (%d, %d)" % [race_id, tx, ty]
