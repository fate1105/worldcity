class_name FoliageRenderer
extends Node2D

## Render cây cối (Foliage) trên các ô Forest và Grass bằng MultiMeshInstance2D
## Cập nhật lại vị trí cây khi địa hình thay đổi

const TILE_PX: float = 16.0
const TREE_COLOR: Color = Color(0.1, 0.5, 0.15)
const GRASS_COLOR: Color = Color(0.3, 0.8, 0.2, 0.7)

var _world_state: WorldState
var _multimesh: MultiMesh
var _mesh_instance: MultiMeshInstance2D
var _rng: RandomNumberGenerator

# Cache the transforms
var _trees: Array[Transform2D] = []
var _tree_colors: Array[Color] = []

func setup(ws: WorldState) -> void:
	_world_state = ws
	_rng = RandomNumberGenerator.new()
	_rng.seed = _world_state.rng_seed
	
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	
	var mesh := QuadMesh.new()
	mesh.size = Vector2(6.0, 6.0) # Kích thước cây
	_multimesh.mesh = mesh
	
	_mesh_instance = MultiMeshInstance2D.new()
	_mesh_instance.multimesh = _multimesh
	add_child(_mesh_instance)
	
	_rebuild_foliage()
	EventBus.tile_changed.connect(_on_tile_changed)

func _on_tile_changed(_tx: int, _ty: int) -> void:
	# Để đơn giản, khi địa hình thay đổi (rất hiếm), rebuild lại toàn bộ cây
	# Trong thực tế có thể tối ưu hơn nếu game bị lag khi dùng quyền thần
	_rebuild_foliage()

func _rebuild_foliage() -> void:
	if not _world_state: return
	var grid: TileGrid = _world_state.tile_grid
	
	_trees.clear()
	_tree_colors.clear()
	
	_rng.seed = _world_state.rng_seed
	
	for y in range(grid.height):
		for x in range(grid.width):
			var idx: int = grid.idx(x, y)
			var terrain: int = grid.terrain[idx]
			var is_forest: bool = (terrain == TileGrid.TileType.FOREST)
			var is_grass: bool = (terrain == TileGrid.TileType.GRASS)
			
			# Không vẽ cây trên ô có đường hoặc nhà
			if grid.road[idx] > 0 or grid.building_id[idx] > 0:
				continue
				
			if is_forest or (is_grass and _rng.randf() < 0.1): # Rừng chắc chắn có cây, cỏ có 10%
				var tree_count = 3 if is_forest else 1
				for i in range(tree_count):
					var cx = x * TILE_PX + _rng.randf_range(2.0, TILE_PX - 2.0)
					var cy = y * TILE_PX + _rng.randf_range(2.0, TILE_PX - 2.0)
					
					var t := Transform2D()
					# Vẽ cây dạng thoi (xoay và scale trước khi đưa về tọa độ thực)
					t = t.rotated(PI / 4.0) 
					var scale_v = _rng.randf_range(0.8, 1.2)
					t = t.scaled(Vector2(scale_v, scale_v))
					t.origin = Vector2(cx, cy)
					
					_trees.append(t)
					if is_forest:
						_tree_colors.append(TREE_COLOR.lightened(_rng.randf_range(-0.1, 0.1)))
					else:
						_tree_colors.append(GRASS_COLOR.lightened(_rng.randf_range(-0.1, 0.1)))

	_multimesh.instance_count = 0 # reset
	_multimesh.instance_count = _trees.size()
	for i in range(_trees.size()):
		_multimesh.set_instance_transform_2d(i, _trees[i])
		_multimesh.set_instance_color(i, _tree_colors[i])
