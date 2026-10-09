class_name Command
extends RefCounted

## Lớp cơ sở cho mọi thao tác làm thay đổi WorldState.
## Cả UI và AI đều phải dùng Command để không trực tiếp sửa state.

var issuer: int = -1
var tick: int = 0

func validate(_state: WorldState) -> Error:
	return OK

func execute(_state: WorldState) -> void:
	pass

func cost(_state: WorldState) -> Dictionary:
	return {}

func describe() -> String:
	return "Unknown Command"
