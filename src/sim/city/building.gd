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

func _init(b_id: int, b_type: String, bx: int, by: int, bw: int, bh: int) -> void:
	id = b_id
	type = b_type
	x = bx
	y = by
	width = bw
	height = bh
