class_name CameraController
extends Camera2D

## Tốc độ kéo chuột (px/px)
const DRAG_SENSITIVITY: float = 1.0
## Tốc độ zoom bằng chuột lăn
const ZOOM_STEP: float = 0.15
## Giới hạn zoom
const ZOOM_MIN: float = 0.25
const ZOOM_MAX: float = 4.0
## Tốc độ zoom mượt (lerp)
const ZOOM_SMOOTH: float = 12.0

var _dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_cam: Vector2 = Vector2.ZERO

## Zoom đích để lerp mượt
var _target_zoom: float = 1.0

## Giới hạn camera (set sau khi biết kích thước bản đồ)
var _limit_rect: Rect2 = Rect2(0.0, 0.0, 2048.0, 2048.0)

## Touch: lưu 2 ngón để zoom chụm
var _touch_distance: float = 0.0
var _touch_midpoint: Vector2 = Vector2.ZERO
var _touch_active: bool = false

func _ready() -> void:
	_target_zoom = zoom.x

func setup_limits(map_width: int, map_height: int, tile_px: int) -> void:
	var world_w: float = float(map_width * tile_px)
	var world_h: float = float(map_height * tile_px)
	_limit_rect = Rect2(0.0, 0.0, world_w, world_h)
	limit_left   = 0
	limit_top    = 0
	limit_right  = int(world_w)
	limit_bottom = int(world_h)
	# Bắt đầu ở giữa bản đồ
	position = Vector2(world_w * 0.5, world_h * 0.5)

func _process(delta: float) -> void:
	# Zoom lerp mượt
	var current_zoom: float = zoom.x
	var new_zoom: float = lerpf(current_zoom, _target_zoom, ZOOM_SMOOTH * delta)
	zoom = Vector2(new_zoom, new_zoom)

func _input(event: InputEvent) -> void:
	# --- Chuột: kéo để di chuyển ---
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_dragging = true
				_drag_start_mouse = mb.position
				_drag_start_cam = position
			else:
				_dragging = false
		# Scroll wheel zoom
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_adjust_zoom(ZOOM_STEP, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_adjust_zoom(-ZOOM_STEP, mb.position)

	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var delta_screen: Vector2 = mm.position - _drag_start_mouse
		position = _drag_start_cam - delta_screen / zoom.x * DRAG_SENSITIVITY

	# --- Cảm ứng: 2 ngón zoom (InputEventMagnifyGesture) ---
	elif event is InputEventMagnifyGesture:
		var mag := event as InputEventMagnifyGesture
		var factor: float = (mag.factor - 1.0)
		_adjust_zoom(factor, mag.position)

	# --- Cảm ứng: kéo 1 ngón (InputEventScreenDrag) ---
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		position -= drag.relative / zoom.x

## Điều chỉnh zoom quanh 1 điểm màn hình
func _adjust_zoom(delta_zoom: float, screen_point: Vector2) -> void:
	var old_zoom: float = _target_zoom
	_target_zoom = clampf(_target_zoom + delta_zoom * _target_zoom, ZOOM_MIN, ZOOM_MAX)
	# Giữ điểm chuột cố định khi zoom
	var world_point_before: Vector2 = (screen_point - get_viewport_rect().size * 0.5) / old_zoom + position
	var world_point_after: Vector2  = (screen_point - get_viewport_rect().size * 0.5) / _target_zoom + position
	position += world_point_before - world_point_after
