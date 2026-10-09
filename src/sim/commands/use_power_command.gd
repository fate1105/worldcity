class_name UsePowerCommand
extends Command

var tx: int
var ty: int
var power_id: String

func _init(x: int, y: int, p_id: String) -> void:
	tx = x
	ty = y
	power_id = p_id

func validate(state: WorldState) -> Error:
	if power_id.is_empty():
		return FAILED
	var pdata: Dictionary = DataDB.power(power_id)
	if pdata.is_empty():
		return FAILED
	var cost_mana: float = float(pdata.get("mana", 0))
	if state.mana < cost_mana:
		return FAILED
	return OK

func execute(_state: WorldState) -> void:
	EventBus.power_used.emit(power_id, tx, ty)

func cost(_state: WorldState) -> Dictionary:
	var pdata: Dictionary = DataDB.power(power_id)
	return {"mana": float(pdata.get("mana", 0))}

func describe() -> String:
	return "Use Power %s at (%d, %d)" % [power_id, tx, ty]
