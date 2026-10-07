extends Node

## GameClock — autoload quản lý tick và thời gian game
## Tick cố định 10/giây ở x1. Tốc độ: 0=pause, 1, 2, 5
## Phát signal qua EventBus, không tự vẽ gì.

const TICKS_PER_SECOND: int = 10   # tick/giây ở x1
const TICKS_PER_DAY: int    = 100  # 1 ngày = 100 tick
const DAYS_PER_MONTH: int   = 30   # 1 tháng = 30 ngày
const MONTHS_PER_YEAR: int  = 12   # 1 năm = 12 tháng

## Số tick tối đa được xử lý trong 1 frame (tránh treo)
const MAX_TICKS_PER_FRAME: int = 20

## Tốc độ hiện tại: 0=pause, 1=x1, 2=x2, 5=x5
var speed: int = 1

## Bộ đếm thời gian thực (giây) để biết khi nào cần tick
var _accum: float = 0.0

## Thời gian mỗi tick (giây) ở tốc độ x1
var _tick_interval: float = 1.0 / float(TICKS_PER_SECOND)

## Trạng thái thời gian game (đồng bộ với WorldState)
var tick: int = 0
var day: int = 1
var month: int = 1
var year: int = 1

func _process(delta: float) -> void:
	if speed == 0:
		return

	_accum += delta * float(speed)
	var ticks_this_frame: int = 0

	while _accum >= _tick_interval and ticks_this_frame < MAX_TICKS_PER_FRAME:
		_accum -= _tick_interval
		_do_tick()
		ticks_this_frame += 1

## Thực hiện 1 tick
func _do_tick() -> void:
	tick += 1
	EventBus.tick_happened.emit(tick)

	# Ngày
	if tick % TICKS_PER_DAY == 0:
		day += 1
		if day > DAYS_PER_MONTH:
			day = 1
			month += 1
			EventBus.month_passed.emit(month, year)
			if month > MONTHS_PER_YEAR:
				month = 1
				year += 1
				EventBus.year_passed.emit(year)
		EventBus.day_passed.emit(day, month, year)

## Đặt tốc độ (0/1/2/5)
func set_speed(new_speed: int) -> void:
	if new_speed not in [0, 1, 2, 5]:
		push_error("GameClock: tốc độ không hợp lệ: %d" % new_speed)
		return
	speed = new_speed
	EventBus.speed_changed.emit(speed)

## Đồng bộ với WorldState sau khi tải game
func sync_from_world(world_state: WorldState) -> void:
	tick  = world_state.tick
	day   = world_state.day
	month = world_state.month
	year  = world_state.year

## Ghi lại vào WorldState trước khi lưu
func sync_to_world(world_state: WorldState) -> void:
	world_state.tick  = tick
	world_state.day   = day
	world_state.month = month
	world_state.year  = year
