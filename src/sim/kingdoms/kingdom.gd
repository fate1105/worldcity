class_name Kingdom
extends RefCounted

## Vương quốc - Dữ liệu cốt lõi (M9a)
## Từ M9, kinh tế (vàng, gỗ, đá) sẽ dần chuyển về đây.

var id: int
var name: String
var race_id: int
var color: Color
var capital_id: int  # ID của Building thủ đô

# Kinh tế vương quốc (sẽ thay thế WorldState.gold trong M9b)
var gold: float = 0.0
var food: float = 0.0
var wood: float = 0.0
var stone: float = 0.0

var population: int = 0
var founded_year: int = 1
var personality: String = "builder"
var king_id: int = -1

func _init(k_id: int, k_name: String, r_id: int, c: Color, cap_id: int, year: int, p: String = "builder") -> void:
	id = k_id
	name = k_name
	race_id = r_id
	color = c
	capital_id = cap_id
	founded_year = year
	personality = p
