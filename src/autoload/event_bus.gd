extends Node

## EventBus — autoload trung tâm, mọi hệ thống giao tiếp qua đây
## Không được gọi trực tiếp giữa các hệ thống, chỉ dùng signal

# --- Thời gian ---
signal tick_happened(tick_number: int)
signal day_passed(day: int, month: int, year: int)
signal month_passed(month: int, year: int)
signal year_passed(year: int)

# --- Mana ---
signal mana_changed(current: float, maximum: float)

# --- Cư dân ---
signal citizen_spawned(id: int)
signal citizen_died(id: int)
signal citizen_born(id: int, parent_a: int, parent_b: int)

# --- Thế giới ---
signal world_generated(seed_val: int)
signal tile_changed(x: int, y: int)

# --- Vương quốc ---
signal kingdom_founded(k_id: int)

# --- Tốc độ ---
signal speed_changed(new_speed: int)  # 0=pause, 1, 2, 5

# --- Command ---
signal command_executed(cmd: Command)

# --- Kinh tế (M7) ---
signal economy_updated(gold: float, food: float)
signal food_shortage(current_food: float, needed: float)
signal budget_crisis(gold: float, deficit_months: int)


# --- Công trình (dùng từ Milestone 6) ---
signal building_placed(building_id: int, x: int, y: int)
signal building_removed(building_id: int)

# --- Quyền năng (dùng từ Milestone 3) ---
signal power_used(power_id: String, x: int, y: int)

# --- Chiến tranh / ngoại giao (dùng từ Milestone 10) ---
signal war_declared(kingdom_a: int, kingdom_b: int)
signal peace_made(kingdom_a: int, kingdom_b: int)
