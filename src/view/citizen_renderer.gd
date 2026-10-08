class_name CitizenRenderer
extends Node2D

## Render toàn bộ cư dân dùng MultiMeshInstance2D để tối đa hóa hiệu năng.
## Đọc dữ liệu trực tiếp từ CitizenStore.

@export var citizen_color: Color = Color.WHITE

var _store: CitizenStore
var _multimesh: MultiMesh
var _mesh_instance: MultiMeshInstance2D
const TILE_PX: float = 16.0

func setup(store: CitizenStore) -> void:
	_store = store

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.instance_count = CitizenStore.MAX_CITIZENS

	# Cấu hình mesh cho cư dân (một hình tròn nhỏ hoặc hình thoi)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(4.0, 4.0)
	_multimesh.mesh = mesh

	_mesh_instance = MultiMeshInstance2D.new()
	_mesh_instance.multimesh = _multimesh

	# Cập nhật màu sắc cho tất cả (mặc định tàng hình/chết, alpha = 0)
	for i: int in range(CitizenStore.MAX_CITIZENS):
		_multimesh.set_instance_color(i, Color.TRANSPARENT)

	add_child(_mesh_instance)

func _process(_delta: float) -> void:
	if _store == null:
		return

	# Quét mảng SoA, cập nhật transform cho các cư dân còn sống
	for id: int in range(CitizenStore.MAX_CITIZENS):
		if _store.alive[id] == 1:
			var t := Transform2D()
			t = t.translated(Vector2(_store.pos_x[id] * TILE_PX, _store.pos_y[id] * TILE_PX))
			_multimesh.set_instance_transform_2d(id, t)

			# Màu sắc dựa trên hạnh phúc/đói
			var color := citizen_color
			if _store.hunger[id] > 70:
				color = Color.ORANGE_RED  # Đói
			_multimesh.set_instance_color(id, color)
		else:
			# Ẩn đi
			_multimesh.set_instance_color(id, Color.TRANSPARENT)
