class_name UsePowerCommand
extends Command

var tx: int
var ty: int
var power_id: String

func _init(x: int, y: int, p_id: String) -> void:
	tx = x
	ty = y
	power_id = p_id

func validate(state: WorldState) -> bool:
	if power_id.is_empty():
		return false
	var pdata: Dictionary = DataDB.power(power_id)
	if pdata.is_empty():
		return false
	var cost: float = float(pdata.get("mana", 0))
	if state.mana < cost:
		return false
	return true

func execute(state: WorldState) -> void:
	EventBus.power_used.emit(power_id, tx, ty)
