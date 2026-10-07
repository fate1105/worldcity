# Quy tắc Godot 4 / GDScript

## API
- Dùng: `CharacterBody2D`, `@onready`, `@export`, `TileMapLayer`, `AStarGrid2D`, `FastNoiseLite`, `MultiMeshInstance2D`, `Callable`, `signal x(...)`, `await`.
- CẤM (Godot 3): `KinematicBody2D`, `TileMap` cũ, `yield`, `onready var`, `export var`, `connect("sig", obj, "method")` kiểu cũ, `OS.get_ticks_msec`.
- Kết nối signal: `signal.connect(callable)`.

## Kiểu dữ liệu
- Mọi `var`, tham số, giá trị trả về đều có kiểu: `var hp: int = 10`, `func f(x: float) -> void:`.
- Dùng `class_name` cho lớp dùng nhiều nơi. Dùng `enum` cho trạng thái.
- Mảng lớn dùng `PackedByteArray`, `PackedInt32Array`, `PackedFloat32Array`, `PackedVector2Array`.

## Phong cách
- File: `snake_case.gd`. Lớp: `PascalCase`. Hằng: `UPPER_SNAKE`. Hàm/biến: `snake_case`. Hàm private bắt đầu `_`.
- Mỗi file một trách nhiệm, tối đa khoảng 400 dòng. Dài hơn thì tách.
- Không dùng `get_node("../..")` dài. Dùng `@export` hoặc signal.
- Không `print` thừa. Dùng `push_warning` / `push_error` cho lỗi thật.

## Scene
- Ưu tiên tạo scene bằng code hoặc file `.tscn` dạng text, rõ ràng, để không phụ thuộc thao tác chuột.
- Việc phải làm tay trong editor (import, Autoload, Export) thì liệt kê từng bước cho tôi.
