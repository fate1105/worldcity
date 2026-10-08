class_name PathfindingSystem
extends RefCounted

## Tìm đường sử dụng AStarGrid2D
## Cập nhật trọng số theo địa hình và đường xá (roads).
## Có hàng đợi xử lý K yêu cầu/tick để tránh lag.

var _astar: AStarGrid2D
var _world_state_ref: WorldState

# Hàng đợi yêu cầu: mỗi yêu cầu lưu { "id": int, "start": Vector2i, "end": Vector2i }
var _queue: Array[Dictionary] = []

func _init(world_state: WorldState) -> void:
	_world_state_ref = world_state
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, world_state.map_width, world_state.map_height)
	_astar.cell_size = Vector2(1, 1)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	_rebuild_all_weights()
	EventBus.tile_changed.connect(update_tile)

## Tính toán lại toàn bộ lưới (khi load game)
func _rebuild_all_weights() -> void:
	var grid := _world_state_ref.tile_grid
	for y: int in range(grid.height):
		for x: int in range(grid.width):
			_update_cell_weight(x, y, grid)

## Gọi khi địa hình / đường thay đổi (từ game.gd)
func update_tile(x: int, y: int) -> void:
	_update_cell_weight(x, y, _world_state_ref.tile_grid)

func _update_cell_weight(x: int, y: int, grid: TileGrid) -> void:
	var i: int = grid.idx(x, y)
	var t: int = grid.terrain[i]
	var has_road: bool = grid.road[i] > 0

	# Biển (0, 1), núi (5), dung nham (9) không đi được
	if t <= 1 or t == 5 or t == 9:
		_astar.set_point_solid(Vector2i(x, y), true)
	else:
		_astar.set_point_solid(Vector2i(x, y), false)
		# Đường đi nhanh (trọng số 1), đất cỏ (2), đầm lầy/tuyết (3)
		if has_road:
			_astar.set_point_weight_scale(Vector2i(x, y), 1.0)
		elif t == 8 or t == 6:
			_astar.set_point_weight_scale(Vector2i(x, y), 3.0)
		else:
			_astar.set_point_weight_scale(Vector2i(x, y), 2.0)

## Yêu cầu tìm đường (Bất đồng bộ - kết quả sẽ trả vào CitizenStore)
func request_path(citizen_id: int, start: Vector2i, end: Vector2i) -> void:
	_queue.push_back({
		"id": citizen_id,
		"start": start,
		"end": end
	})

## Xử lý hàng đợi mỗi tick (tối đa K request)
func process_queue(max_requests: int = 20) -> void:
	var processed: int = 0
	while not _queue.is_empty() and processed < max_requests:
		var req: Dictionary = _queue.pop_front()
		processed += 1
		var id: int = req["id"]
		# Kiểm tra nếu dân còn sống
		if _world_state_ref.citizens.alive[id] == 1:
			var path := _astar.get_id_path(req["start"], req["end"])
			if path.size() > 0:
				_world_state_ref.citizens.set_path(id, path)
			else:
				# Không có đường
				_world_state_ref.citizens.set_path(id, [])
