class_name WorldView
extends Node2D

## Kích thước mỗi ô tính theo pixel
const TILE_PX: int = 16
## Kích thước chunk (ô)
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

## Mỗi chunk là 1 Sprite2D hiển thị Image 32x32 được scale lên
var _chunk_sprites: Array[Sprite2D] = []
## Chunk nào cần vẽ lại
var _dirty_chunks: PackedByteArray

var _camera_ref: Camera2D

func setup(world_state: WorldState, camera: Camera2D) -> void:
	_world_state = world_state
	_camera_ref = camera

	_chunks_x = int(ceil(float(world_state.map_width)  / float(CHUNK_SIZE)))
	_chunks_y = int(ceil(float(world_state.map_height) / float(CHUNK_SIZE)))

	var total_chunks: int = _chunks_x * _chunks_y
	_dirty_chunks = PackedByteArray()
	_dirty_chunks.resize(total_chunks)
	_dirty_chunks.fill(1)

	_chunk_sprites.resize(total_chunks)
	for ci: int in range(total_chunks):
		var cx: int = ci % _chunks_x
		var cy: int = ci / _chunks_x
		var sprite := Sprite2D.new()
		sprite.name = "Chunk_%d" % ci
		# Sprite2D gốc ở tâm → dịch về góc trên-trái
		sprite.centered = false
		sprite.position = Vector2(cx * CHUNK_SIZE * TILE_PX, cy * CHUNK_SIZE * TILE_PX)
		sprite.scale = Vector2(TILE_PX, TILE_PX)
		# Tắt filter để pixel art giữ nét
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		_chunk_sprites[ci] = sprite

	_rebuild_all_chunks()

## Đánh dấu chunk chứa toạ độ ô (tx, ty) cần vẽ lại
func mark_dirty(tx: int, ty: int) -> void:
	var cx: int = tx / CHUNK_SIZE
	var cy: int = ty / CHUNK_SIZE
	if cx < _chunks_x and cy < _chunks_y:
		_dirty_chunks[cy * _chunks_x + cx] = 1

func _process(_delta: float) -> void:
	_flush_dirty_chunks()

func _flush_dirty_chunks() -> void:
	for ci: int in range(_dirty_chunks.size()):
		if _dirty_chunks[ci] == 1:
			_build_chunk(ci)
			_dirty_chunks[ci] = 0

func _rebuild_all_chunks() -> void:
	for ci: int in range(_chunk_sprites.size()):
		_build_chunk(ci)
		_dirty_chunks[ci] = 0

## Vẽ chunk bằng Image 32x32 rồi gán làm ImageTexture cho Sprite2D
func _build_chunk(chunk_idx: int) -> void:
	var cx: int = chunk_idx % _chunks_x
	var cy: int = chunk_idx / _chunks_x

	var start_x: int = cx * CHUNK_SIZE
	var start_y: int = cy * CHUNK_SIZE
	var end_x: int = mini(start_x + CHUNK_SIZE, _world_state.map_width)
	var end_y: int = mini(start_y + CHUNK_SIZE, _world_state.map_height)

	var img_w: int = end_x - start_x
	var img_h: int = end_y - start_y

	var img := Image.create(img_w, img_h, false, Image.FORMAT_RGB8)
	var grid: TileGrid = _world_state.tile_grid

	for ty: int in range(start_y, end_y):
		for tx: int in range(start_x, end_x):
			var tile_type: int = grid.get_terrain(tx, ty)
			var color: Color = TILE_COLORS[tile_type]
			img.set_pixel(tx - start_x, ty - start_y, color)

	_chunk_sprites[chunk_idx].texture = ImageTexture.create_from_image(img)
