class_name WorldView
extends Node2D

## Kích thước mỗi ô tính theo pixel
const TILE_PX: int = 16
## Kích thước chunk (32x32 ô = 512x512 px mỗi chunk)
const CHUNK_SIZE: int = 32

## Màu placeholder cho từng loại ô (thay sprite ở Milestone 13)
const TILE_COLORS: Array[Color] = [
	Color(0.05, 0.15, 0.55),  # 0 DEEP_SEA
	Color(0.15, 0.40, 0.80),  # 1 SHALLOW_SEA
	Color(0.90, 0.85, 0.55),  # 2 SAND
	Color(0.35, 0.72, 0.25),  # 3 GRASS
	Color(0.12, 0.42, 0.10),  # 4 FOREST
	Color(0.50, 0.45, 0.40),  # 5 MOUNTAIN
	Color(0.90, 0.95, 1.00),  # 6 SNOW
	Color(0.88, 0.70, 0.30),  # 7 DESERT
	Color(0.25, 0.45, 0.30),  # 8 SWAMP
	Color(0.95, 0.25, 0.05),  # 9 LAVA
]

var _world_state: WorldState
var _chunks_x: int
var _chunks_y: int

## Mỗi chunk là 1 MeshInstance2D với ImmediateMesh để vẽ nhanh
var _chunk_nodes: Array[MeshInstance2D] = []
## Chunk nào cần vẽ lại
var _dirty_chunks: PackedByteArray

## Camera rect để chỉ cập nhật chunk trong tầm nhìn
var _camera_ref: Camera2D

func setup(world_state: WorldState, camera: Camera2D) -> void:
	_world_state = world_state
	_camera_ref = camera
	_chunks_x = int(ceil(float(world_state.map_width) / float(CHUNK_SIZE)))
	_chunks_y = int(ceil(float(world_state.map_height) / float(CHUNK_SIZE)))

	var total_chunks: int = _chunks_x * _chunks_y
	_dirty_chunks = PackedByteArray()
	_dirty_chunks.resize(total_chunks)
	_dirty_chunks.fill(1)

	# Tạo trước tất cả chunk node
	_chunk_nodes.resize(total_chunks)
	for ci: int in range(total_chunks):
		var mesh_node := MeshInstance2D.new()
		mesh_node.name = "Chunk_%d" % ci
		add_child(mesh_node)
		_chunk_nodes[ci] = mesh_node

	_rebuild_all_chunks()

## Đánh dấu chunk chứa toạ độ ô (tx, ty) cần vẽ lại
func mark_dirty(tx: int, ty: int) -> void:
	var cx: int = tx / CHUNK_SIZE
	var cy: int = ty / CHUNK_SIZE
	_dirty_chunks[cy * _chunks_x + cx] = 1

func _process(_delta: float) -> void:
	_flush_dirty_chunks()

## Vẽ lại các chunk bẩn (dirty)
func _flush_dirty_chunks() -> void:
	for ci: int in range(_dirty_chunks.size()):
		if _dirty_chunks[ci] == 1:
			_build_chunk(ci)
			_dirty_chunks[ci] = 0

func _rebuild_all_chunks() -> void:
	for ci: int in range(_chunk_nodes.size()):
		_build_chunk(ci)
		_dirty_chunks[ci] = 0

## Vẽ 1 chunk bằng ImmediateMesh (quad cho mỗi ô)
func _build_chunk(chunk_idx: int) -> void:
	var cx: int = chunk_idx % _chunks_x
	var cy: int = chunk_idx / _chunks_x

	var start_x: int = cx * CHUNK_SIZE
	var start_y: int = cy * CHUNK_SIZE
	var end_x: int = mini(start_x + CHUNK_SIZE, _world_state.map_width)
	var end_y: int = mini(start_y + CHUNK_SIZE, _world_state.map_height)

	var grid: TileGrid = _world_state.tile_grid

	var mesh := ImmediateMesh.new()

	for ty: int in range(start_y, end_y):
		for tx: int in range(start_x, end_x):
			var tile_type: int = grid.get_terrain(tx, ty)
			var color: Color = TILE_COLORS[tile_type]

			var px: float = float(tx * TILE_PX)
			var py: float = float(ty * TILE_PX)
			var px2: float = px + float(TILE_PX)
			var py2: float = py + float(TILE_PX)

			# Thêm 2 tam giác tạo thành 1 quad
			mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			mesh.surface_set_color(color)

			mesh.surface_add_vertex(Vector3(px,  py,  0.0))
			mesh.surface_add_vertex(Vector3(px2, py,  0.0))
			mesh.surface_add_vertex(Vector3(px2, py2, 0.0))

			mesh.surface_add_vertex(Vector3(px,  py,  0.0))
			mesh.surface_add_vertex(Vector3(px2, py2, 0.0))
			mesh.surface_add_vertex(Vector3(px,  py2, 0.0))

			mesh.surface_end()

	# Gán material không nhận ánh sáng để giữ màu chính xác
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_chunk_nodes[chunk_idx].mesh = mesh
	if mesh.get_surface_count() > 0:
		_chunk_nodes[chunk_idx].material_override = mat
