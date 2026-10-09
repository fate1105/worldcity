class_name Building
extends RefCounted

var id: int
var type: String
var x: int
var y: int
var width: int
var height: int
var level: int = 1
var active: bool = true

# M7 – kinh tế
var workers_assigned: int = 0  # dân đang được phân công làm việc ở đây
var home_citizens: PackedInt32Array  # id cư dân đang ở nhà này

func _init(b_id: int, b_type: String, bx: int, by: int, bw: int, bh: int) -> void:
	id = b_id
	type = b_type
	x = bx
	y = by
	width = bw
	height = bh
	home_citizens = PackedInt32Array()
