class_name Command
extends RefCounted

## Lớp cơ sở cho mọi thao tác làm thay đổi WorldState.
## Cả UI và AI đều phải dùng Command để không trực tiếp sửa state.

func validate(_state: WorldState) -> bool:
	return true

func execute(_state: WorldState) -> void:
	pass
