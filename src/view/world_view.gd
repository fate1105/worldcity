class_name WorldView
extends Node2D

## Kích thước mỗi ô tính theo pixel
const TILE_PX: int = 16
## Kích thước chunk (ô)
const CHUNK_SIZE: int = 32

## Màu placeholder cho từng loại ô
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

## Màu lửa overlay
const FIRE_COLOR_HIGH: Color = Color(1.0, 0.35, 0.0, 0.85)
const FIRE_COLOR_LOW:  Color = Color(1.0, 0.65, 0.0, 0.45)
const ROAD_COLOR: Color = Color(0.25, 0.25, 0.25)



var _world_state: WorldState
var _chunks_x: int
var _chunks_y: int
var _chunk_sprites: Array[Sprite2D] = []
var _border_sprites: Array[Sprite2D] = []
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
		sprite.centered = false
		sprite.position = Vector2(cx * CHUNK_SIZE * TILE_PX, cy * CHUNK_SIZE * TILE_PX)
		sprite.scale = Vector2(TILE_PX, TILE_PX)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		_chunk_sprites[ci] = sprite
		
		var b_sprite := Sprite2D.new()
		b_sprite.name = "Border_%d" % ci
		b_sprite.centered = false
		b_sprite.position = sprite.position
		b_sprite.scale = sprite.scale
		b_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b_sprite.z_index = 1 # Vẽ đè lên chunk
		add_child(b_sprite)
		_border_sprites.append(b_sprite)

	# Lắng nghe signal tile_changed từ EventBus để đánh dirty chunk
	EventBus.tile_changed.connect(_on_tile_changed)

	_rebuild_all_chunks()

## Đánh dirty chunk chứa toạ độ ô (tx, ty)
func mark_dirty(tx: int, ty: int) -> void:
	var cx: int = tx / CHUNK_SIZE
	var cy: int = ty / CHUNK_SIZE
	if cx < _chunks_x and cy < _chunks_y:
		_dirty_chunks[cy * _chunks_x + cx] = 1

func _on_tile_changed(tx: int, ty: int) -> void:
	mark_dirty(tx, ty)

func _process(_delta: float) -> void:
	_flush_dirty_chunks()
	
	if _camera_ref:
		var show_borders: bool = _camera_ref.zoom.x <= 0.6
		for b_sprite in _border_sprites:
			b_sprite.visible = show_borders

func _flush_dirty_chunks() -> void:
	for ci: int in range(_dirty_chunks.size()):
		if _dirty_chunks[ci] == 1:
			_build_chunk(ci)
			_dirty_chunks[ci] = 0

func _rebuild_all_chunks() -> void:
	for ci: int in range(_chunk_sprites.size()):
		_build_chunk(ci)
		_dirty_chunks[ci] = 0

## Vẽ chunk: terrain màu + overlay lửa
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
	var img_border := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	var grid: TileGrid = _world_state.tile_grid

	for ty: int in range(start_y, end_y):
		for tx: int in range(start_x, end_x):
			var i: int = grid.idx(tx, ty)
			var tile_type: int = grid.terrain[i]
			var color: Color = TILE_COLORS[tile_type]

			# Công trình (Building)
			var b_id: int = grid.building_id[i]
			if b_id > 0 and _world_state.buildings.has(b_id):
				var b: Building = _world_state.buildings[b_id]
				if b.type.begins_with("house"):
					color = Color(0.2, 0.6, 0.2)
				elif b.type == "market" or b.type.begins_with("shop"):
					color = Color(0.2, 0.2, 0.8)
				else:
					color = Color(0.8, 0.6, 0.1) # Farm, industry
				# Vẽ viền nếu là góc trên trái
				if cx == b.x and cy == b.y:
					color = color.lightened(0.2)
			else:
				# Overlay đường xá
				if grid.road[i] > 0:
					color = color.blend(ROAD_COLOR.lerp(Color.TRANSPARENT, 0.3))

			# Overlay lãnh thổ vương quốc
			var o_id: int = grid.owner_id[i]
			var border_color := Color.TRANSPARENT
			if o_id != -1 and _world_state.kingdoms.has(o_id):
				var kingdom: Kingdom = _world_state.kingdoms[o_id]
				var k_color: Color = kingdom.color
				color = color.blend(Color(k_color.r, k_color.g, k_color.b, 0.4))
				
				# Kiểm tra xem có phải viền không (viền = có ô xung quanh khác o_id)
				var is_border = false
				var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
				for d in dirs:
					var nx: int = tx + d.x
					var ny: int = ty + d.y
					if grid.in_bounds(nx, ny) and grid.owner_id[grid.idx(nx, ny)] != o_id:
						is_border = true
						break
				if is_border:
					border_color = k_color
					border_color.a = 1.0

			# Overlay lửa
			var fire_val: int = grid.fire[i]
			if fire_val > 0:
				var intensity: float = clampf(float(fire_val) / 120.0, 0.0, 1.0)
				var fire_color: Color = FIRE_COLOR_LOW.lerp(FIRE_COLOR_HIGH, intensity)
				color = color.blend(fire_color)

			img.set_pixel(tx - start_x, ty - start_y, color)
			img_border.set_pixel(tx - start_x, ty - start_y, border_color)

	_chunk_sprites[chunk_idx].texture = ImageTexture.create_from_image(img)
	_border_sprites[chunk_idx].texture = ImageTexture.create_from_image(img_border)
