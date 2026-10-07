class_name TileGrid
extends RefCounted

## Các loại ô – phải khớp với terrain.json và atlas tileset
enum TileType {
	DEEP_SEA    = 0,
	SHALLOW_SEA = 1,
	SAND        = 2,
	GRASS       = 3,
	FOREST      = 4,
	MOUNTAIN    = 5,
	SNOW        = 6,
	DESERT      = 7,
	SWAMP       = 8,
	LAVA        = 9,
}

var width: int
var height: int

# Mỗi layer là 1 PackedArray kích thước width*height
var terrain: PackedByteArray
var height_map: PackedByteArray   # 0-255
var fertility: PackedByteArray    # 0-255
var owner_id: PackedInt32Array    # id vương quốc, -1 = không ai
var building_id: PackedInt32Array # id công trình, -1 = không có
var road: PackedByteArray         # 0/1
var power: PackedByteArray        # 0/1
var water: PackedByteArray        # 0/1
var pollution: PackedByteArray    # 0-255
var happiness_map: PackedByteArray # 0-255
var fire: PackedByteArray         # 0=không cháy, 1-200=thời gian cháy còn lại (ticks)

func _init(w: int, h: int) -> void:
	width = w
	height = h
	var size: int = w * h
	terrain = PackedByteArray()
	terrain.resize(size)
	height_map = PackedByteArray()
	height_map.resize(size)
	fertility = PackedByteArray()
	fertility.resize(size)
	owner_id = PackedInt32Array()
	owner_id.resize(size)
	owner_id.fill(-1)
	building_id = PackedInt32Array()
	building_id.resize(size)
	building_id.fill(-1)
	road = PackedByteArray()
	road.resize(size)
	power = PackedByteArray()
	power.resize(size)
	water = PackedByteArray()
	water.resize(size)
	pollution = PackedByteArray()
	pollution.resize(size)
	happiness_map = PackedByteArray()
	happiness_map.resize(size)
	happiness_map.fill(50)
	fire = PackedByteArray()
	fire.resize(size)

## Chuyển (x, y) → index tuyến tính
func idx(x: int, y: int) -> int:
	return y * width + x

## Kiểm tra toạ độ hợp lệ
func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

## Lấy loại ô
func get_terrain(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return TileType.DEEP_SEA
	return terrain[idx(x, y)]

## Đặt loại ô
func set_terrain(x: int, y: int, t: int) -> void:
	if in_bounds(x, y):
		terrain[idx(x, y)] = t

## Serialize ra Dictionary để lưu
func to_dict() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"terrain": terrain.hex_encode(),
		"height_map": height_map.hex_encode(),
		"fertility": fertility.hex_encode(),
	}

## Deserialize từ Dictionary
static func from_dict(d: Dictionary) -> TileGrid:
	var w: int = d.get("width", 128)
	var h: int = d.get("height", 128)
	var g := TileGrid.new(w, h)
	if d.has("terrain"):
		g.terrain = PackedByteArray(d["terrain"].hex_decode())
	if d.has("height_map"):
		g.height_map = PackedByteArray(d["height_map"].hex_decode())
	if d.has("fertility"):
		g.fertility = PackedByteArray(d["fertility"].hex_decode())
	return g
