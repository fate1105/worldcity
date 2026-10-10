# WORLDCITY: Godot Tech Spec (v2, kiến trúc Command + AI tự vận hành)

> **Kiến trúc kỹ thuật nằm ở file này.** Gameplay: `GDD_WorldCity.md`. Thiết kế AI chi tiết: `AUTONOMOUS_MODE.md`.
> Mâu thuẫn: công nghệ và lộ trình milestone theo file này; gameplay theo GDD.

---

## 1. Quyết định công nghệ

| Hạng mục | Chọn | Lý do |
|---|---|---|
| Engine | **Godot 4.x (stable mới nhất)** | Miễn phí, nhẹ, 2D mạnh, xuất Android/iOS/PC/Web |
| Ngôn ngữ | **GDScript có kiểu (typed)** | AI viết tốt, lặp nhanh. Phần nặng về sau có thể dùng C# hoặc GDExtension |
| Renderer | **Mobile** (Compatibility cho máy yếu) | Tiết kiệm pin |
| Góc nhìn | **Top-down 2D, tile 16x16** | Dễ mở rộng bản đồ lớn. Isometric để sau |
| Bản đồ | **TileMapLayer** chia chunk | API mới Godot 4.3+ |
| Đường đi | **AStarGrid2D** (+ flow field cho đám đông) | Có sẵn, nhanh |
| Dữ liệu | **JSON** (+ Resource khi cần) | Chỉnh số liệu không sửa code |
| Version control | **Git** | Commit sau mỗi milestone |
| Test | **GUT** + script mô phỏng headless | Bắt lỗi logic và cân bằng |
| IDE/Agent | **Antigravity** (đọc `AGENTS.md`, `.agents/`) | Xem mục 12 |

---

## 2. Nguyên tắc kiến trúc

1. **Tách Mô phỏng (sim) khỏi Hiển thị (view).** Logic trong `RefCounted`/dữ liệu thuần, không phụ thuộc Node/SceneTree. View chỉ đọc state và vẽ.
2. **Mọi thay đổi thế giới đi qua `Command`.** Công cụ người chơi, quyền thần và AI vương quốc **dùng chung** hệ Command. UI không sửa state trực tiếp.
3. **AI chỉ đọc state và phát Command.** Không gian lận, cùng luật với người chơi.
4. **Không 1 Node cho mỗi cư dân.** Cư dân là dữ liệu (PackedArray), vẽ bằng MultiMesh.
5. **Data-driven.** Nhà, chủng tộc, trait, quyền năng, thiên tai, AI khai báo trong `data/*.json`.
6. **Giao tiếp bằng signal qua `EventBus`.** Hệ thống không gọi chéo trực tiếp.
7. **Tick cố định + time-slicing.** Không cập nhật mọi thứ mỗi frame.
8. **RNG có seed**, seed nằm trong `WorldState`, để tái hiện lỗi và lưu/tải chuẩn.
9. **Mô phỏng chạy được headless** (không hình) để kiểm thử cân bằng 100-300 năm.
10. **GDScript có kiểu ở mọi nơi.**

---

## 3. Cấu trúc thư mục

```
worldcity/
├─ project.godot
├─ AGENTS.md                      # luật cốt lõi cho agent
├─ .agents/
│  ├─ rules/                      # godot4.md, architecture.md, discipline.md
│  └─ workflows/                  # milestone, fix-bug, review-architecture, perf-check
├─ docs/                          # 3 file thiết kế này
├─ data/                          # JSON cân bằng
│  ├─ terrain.json races.json traits.json powers.json
│  ├─ buildings.json disasters.json events.json
│  ├─ balance.json
│  └─ ai.json                     # tính cách, trọng số, ngưỡng AI
├─ src/
│  ├─ autoload/                   # event_bus, game_clock, data_db, save_system, settings
│  ├─ sim/                        # LOGIC THUẦN
│  │  ├─ world_state.gd world_gen.gd tile_grid.gd scheduler.gd
│  │  ├─ commands/                # command.gd + place_road, set_zone, place_building, ...
│  │  ├─ citizens/                # citizen_store, citizen_ai, needs, lifecycle, genealogy
│  │  ├─ city/                    # zoning, demand, buildings, utilities, economy
│  │  ├─ kingdoms/                # kingdom, borders, succession, diplomacy_state
│  │  ├─ ai/                      # kingdom_brain, city_planner, economy_manager,
│  │  │                           # population_manager, military_advisor, diplomacy_advisor, memory
│  │  ├─ war/                     # armies, combat, siege
│  │  ├─ powers/                  # quyền thần
│  │  ├─ events/                  # disasters, event_director, drama_director
│  │  └─ chronicle/               # chronicle.gd, entry.gd, importance
│  ├─ view/                       # world_view, citizen_renderer, camera_controller, overlays, fx
│  ├─ ui/                         # hud, toolbar, panels, timeline, charts, minimap, popups
│  ├─ tools/                      # brush, zone_tool, road_tool (chỉ tạo Command)
│  └─ observer/                   # auto_camera, follow_target, world_summary
├─ tools/
│  └─ sim_runner.gd               # chạy mô phỏng headless + báo cáo
├─ assets/                        # tilesets, sprites, audio, fonts, shaders
├─ scenes/                        # main, main_menu, game
└─ tests/                         # GUT
```

---

## 4. Autoload

| Tên | Việc |
|---|---|
| `EventBus` | Chứa toàn bộ signal: `citizen_died`, `war_declared`, `month_passed`, `command_executed`, `chronicle_entry_added`... |
| `GameClock` | Tick, tốc độ (0/1/2/5/10/50x), ngày/tháng/năm, signal `tick`, `day_passed`, `month_passed`, `year_passed` |
| `DataDB` | Nạp JSON, tra cứu, kiểm tra schema, báo lỗi rõ |
| `SaveSystem` | Lưu/tải `WorldState`, có phiên bản và migrate |
| `Settings` | Cài đặt người chơi `user://settings.cfg` |

---

## 5. Dữ liệu mô phỏng

**Lưới ô:** mỗi layer một `PackedArray` kích thước `W*H`, `idx = y*W + x`.
```gdscript
var terrain: PackedByteArray
var height: PackedByteArray
var fertility: PackedByteArray
var owner_id: PackedInt32Array     # id vương quốc, -1 = vô chủ
var building_id: PackedInt32Array
var road: PackedByteArray
var power: PackedByteArray
var water: PackedByteArray
var pollution: PackedByteArray
var happiness_map: PackedByteArray
```

**Cư dân (SoA):**
```gdscript
class_name CitizenStore
var count: int
var alive: PackedByteArray
var pos_x: PackedFloat32Array
var pos_y: PackedFloat32Array
var age: PackedInt32Array
var hunger: PackedByteArray
var happiness: PackedByteArray
var race_id: PackedByteArray
var kingdom_id: PackedInt32Array
var home_id: PackedInt32Array
var job_id: PackedInt32Array
var state: PackedByteArray         # enum AIState
var parent_a: PackedInt32Array     # gia phả
var parent_b: PackedInt32Array
var traits: PackedInt32Array       # bitmask
var name_id: PackedInt32Array
var gender: PackedByteArray        # 0: Nam, 1: Nữ
var spouse_id: PackedInt32Array
var wealth: PackedInt32Array
var action_desc: Array[String]
# 8 chỉ số RPG (Sức mạnh, Nhanh nhẹn, Trí tuệ, Thể lực, Sức hút, Khéo léo, May mắn, Dũng cảm)
var stat_str: PackedByteArray
var stat_agi: PackedByteArray
var stat_int: PackedByteArray
var stat_end: PackedByteArray
var stat_cha: PackedByteArray
var stat_crf: PackedByteArray
var stat_lck: PackedByteArray
var stat_brv: PackedByteArray
```
Nếu SoA khó cho giai đoạn đầu, cho phép `class Citizen extends RefCounted` rồi chuyển SoA ở M12c. **Cấm dùng Node.**

**Công trình, vương quốc, quân đội:** `RefCounted`/`Resource` thường.

---

## 6. Hệ thống Command

```gdscript
class_name Command extends RefCounted
var issuer: int          # kingdom id; -1 = thần/người chơi trực tiếp
var tick: int
func validate(state: WorldState) -> Error: ...   # OK hoặc mã lỗi/lý do
func execute(state: WorldState) -> void: ...     # chỉ gọi khi validate OK
func cost(state: WorldState) -> Dictionary: ...  # tài nguyên tiêu hao
func describe() -> String: ...                   # cho log/Chronicle/debug
```

**Danh sách Command:** `PlaceRoad, SetZone, PlaceBuilding, Demolish, SetTax, FoundCity, RaiseArmy, MoveArmy, DeclareWar, ProposeAlliance, ProposePeace, SendGift, StartTrade, UsePower (quyền thần), PaintTerrain, SpawnCreature`.

**Luồng:**
```
Tool (UI) hoặc KingdomBrain ──► CommandBus.submit(cmd)
CommandBus: validate → trừ chi phí → execute → phát signal command_executed → (tùy loại) ghi Chronicle
```
- Có **log lệnh** (vòng đệm) phục vụ debug, thống kê thrashing, replay.
- Lệnh bị từ chối ghi `reason`, AI dùng để học (Memory) và tránh lặp lại.
- Lệnh có `issuer` để áp luật theo vương quốc (chỉ xây trong lãnh thổ mình, v.v.).

---

## 7. Tick và Scheduler

- `GameClock` chạy `_physics_process` với tick cố định **10/giây ở x1**, nhân theo tốc độ; có **giới hạn số tick tối đa mỗi frame** để không treo.

| Tần suất | Việc |
|---|---|
| Mỗi tick | Di chuyển cư dân/quân, giao tranh, lửa lan, hiệu ứng |
| Mỗi ngày (100 tick) | Nhu cầu cá nhân, mọc nhà, điện/nước, ô nhiễm |
| Mỗi tháng | Kinh tế, sinh sản, **KingdomBrain suy nghĩ**, sự kiện |
| Mỗi năm | Lão hóa, thống kê, thành tựu, Drama Director |

- **Time-slicing:** cư dân chia 10 nhóm, tick `n` xử lý nhóm `n % 10`; có ngân sách thời gian mỗi frame (≈4 ms). Quá nhiều vương quốc: mỗi tháng chỉ vài cái "suy nghĩ", luân phiên.
- **Tìm đường:** hàng đợi, tối đa K yêu cầu/tick, cache theo cặp vùng.
- **Tốc độ cao (x10, x50):** giảm hiệu ứng/vẽ, vẫn đúng logic (tick đầy đủ).

---

## 8. Hiển thị (view)

- **Địa hình:** `TileMapLayer` chunk 32x32, cập nhật chunk bẩn (dirty), chỉ bật chunk trong camera.
- **Cư dân/quân:** `MultiMeshInstance2D` (1 draw call/hàng nghìn sprite), chỉ vẽ trong camera, tô màu theo chủng tộc/vương quốc bằng code.
- **Công trình:** sprite theo ô, `TileMapLayer` riêng hoặc MultiMesh.
- **Camera2D:** kéo, zoom (chuột + cảm ứng), giới hạn biên, chuyển cảnh mượt cho Auto-Camera.
- **Overlay + biên giới:** `Image`→`ImageTexture` hoặc shader từ `owner_id`.
- **Hiệu ứng:** particle (lửa, khói, mưa, nổ, sét zigzag bằng code), shader nước. Không cần ảnh ngoài.
- Placeholder (ô màu) từ M1 tới M12; sprite thật ở M13, ánh xạ bằng trường `sprite` trong JSON.

---

## 9. Observer và UI

- `InputRouter` hỗ trợ chuột + cảm ứng. Công cụ kế thừa `Tool` (`begin/update/end`), **chỉ tạo Command**.
- **Observer:** `AutoCamera` (chấm điểm sự kiện theo `importance`, chọn mục tiêu, bay mượt, cooldown để không giật), `FollowTarget`, `WorldSummary` (tóm tắt theo thế kỷ).
- UI dùng `Control` + `Theme`, responsive, nút ≥ 48 px. UI cập nhật bằng signal, không đọc state mỗi frame.
- Panel: thông tin, **Timeline (Chronicle)**, biểu đồ (dân số, quân sự, kinh tế, lãnh thổ), bản đồ chính trị, minimap, AI debug.
- Dịch: `tr()` + CSV (Việt + Anh) ngay từ đầu.

---

## 10. Lưu / Tải

- `WorldState.to_dict()/from_dict()`; Packed array lưu nhị phân, nén ZSTD (`FileAccess.COMPRESSION_ZSTD`).
- `save_version` + hàm `migrate` mỗi khi đổi cấu trúc. Lưu `user://saves/slot_N.sav`, autosave mỗi năm game.
- Lưu cả: seed RNG, Chronicle, bộ nhớ AI (`Memory`), log lệnh gần đây.
- `validate()` sau khi tải (id trỏ đúng, không âm, tổng dân khớp).

---

## 11. Kiểm thử, hiệu năng, xuất bản

### 11.1 Mô phỏng headless (`tools/sim_runner.gd`)
```
godot --headless --path . -s tools/sim_runner.gd -- --years 100 --seeds 20 --out reports/
```
Mỗi lần chạy xuất báo cáo (JSON + tóm tắt): dân số theo năm, số vương quốc còn lại, số chiến tranh, thời điểm sụp đổ, số Command bị từ chối, tỷ lệ xây-rồi-phá (thrashing), ms trung bình mỗi hệ thống.

**Tiêu chí lành mạnh (AI được coi là ổn khi):**
- ≥ 80% seed còn ≥ 2 vương quốc sau 100 năm.
- Dân số không sụp về 0 và không tăng vô hạn.
- Mỗi thế giới có cả chiến tranh lẫn hòa bình dài.
- Thrashing dưới ngưỡng trong `data/ai.json`.
- Không treo, không lỗi script trong 300 năm.

### 11.2 Test và đo hiệu năng
- **GUT:** kinh tế cân bằng, demand, A*, Command validate/execute, save/load khứ hồi, tính tất định theo seed.
- **Mục tiêu:** 60 FPS với 1000 cư dân (128x128) trên điện thoại tầm trung; 30 FPS ở 3000 cư dân.
- **Debug overlay:** FPS, số cư dân, ms từng hệ thống, số yêu cầu tìm đường. Đo bằng `Time.get_ticks_usec()` trước khi tối ưu.
- **Android:** Android Build Template + JDK + SDK, Export Preset, `Use Gradle Build`, ký bằng keystore.
- CI (tùy chọn): GitHub Actions chạy GUT + 1 lượt sim_runner ngắn.

---

## 12. Làm việc với Antigravity

- Luật cốt lõi ở `AGENTS.md` (giữ **dưới 12.000 ký tự**); luật chi tiết chia nhỏ trong `.agents/rules/`; quy trình trong `.agents/workflows/` (`/milestone N`, `/fix-bug`, `/review-architecture`, `/perf-check`).
- Thêm Godot vào **PATH** để agent tự chạy `godot --headless`.
- **Không chạy nhiều agent song song sửa cùng file.** Làm tuần tự từng milestone.
- Agent hay dùng nhầm API Godot 3: nhắc xem `.agents/rules/godot4.md`. Không ổn thì đổi model.
- Commit Git trước và sau mỗi milestone. Lỗi thì dán nguyên log kèm `/fix-bug`.
- Mỗi 2-3 milestone chạy `/review-architecture`.

---

## 13. Lộ trình Milestone

Mỗi milestone: chạy được, headless không lỗi, commit Git, rồi mới tiếp. Bạn đã làm **M0-M6**.

| # | Milestone | Kết quả cần có | Trạng thái |
|---|---|---|---|
| 0 | Khởi tạo dự án | Cấu trúc thư mục, autoload rỗng, scene chạy được | Xong |
| 1 | Thế giới + camera | TileGrid, WorldGen, TileMapLayer chunk, camera kéo/zoom, FPS overlay | Xong |
| 2 | Clock + scheduler + data | GameClock, nút tốc độ, DataDB, EventBus, HUD ngày | Xong |
| 3 | God mode cơ bản | Cọ địa hình, mana, mưa/sét/lửa/núi lửa | Xong |
| 4 | Cư dân cơ bản | CitizenStore, đi lại, đói, tuổi, chết, MultiMesh, bấm xem | Xong |
| 5 | Đường đi | AStarGrid2D, hàng đợi, đường tăng tốc | Xong |
| 6 | Xây dựng hữu cơ (Bỏ Zone) | AI tự chọn đất cất nhà, tự tạo đường, tự mở biên giới (Thay thế hệ thống Zone) | Xong |
| 7 | Cư dân nâng cao | Nhu cầu sinh hoạt, Chu kỳ Ngày Đêm, Hệ thống tiền tệ (Wealth) | Xong |
| 8 | 8 Chỉ số & Trait RPG | 8 chỉ số cá nhân, Trait không random, di truyền chỉ số, Hôn nhân, Gia phả | Xong |
| 9 | Vương quốc cơ bản | AI tự phát triển lãnh thổ và điều phối tài nguyên, chuyển ngôi | Xong |
| **10a** | **Ngoại giao** | Quan hệ, giao thương, liên minh, cống nạp (AI tự quyết) | **Làm tiếp** |
| 10b | Chiến tranh | Quân đội, MilitaryAdvisor, tuyên chiến, chiếm thành, đình chiến | |
| 11 | Thiên tai + sự kiện + **Chronicle** | EventDirector, DramaDirector, sự kiện lựa chọn, nhật ký có `importance` | |
| 12a | **Chế độ quan sát** | AutoCamera, Timeline, biểu đồ, bản đồ chính trị, tốc độ x50 | |
| 12b | **Sim headless + cân bằng** | `sim_runner`, báo cáo, chỉnh `balance.json`/`ai.json` đạt tiêu chí mục 11.1 | |
| 12c | Lưu/Tải + tối ưu | SaveSystem, migrate, SoA, profile, time-slicing đầy đủ | |
| 13 | Đồ họa + âm thanh | Thay placeholder bằng sprite, SFX, nhạc, shader nước | |
| 14 | Đóng gói | Export Android/PC, menu chính, cài đặt, dịch, icon, test thiết bị thật | |

### Prompt mẫu

**M6.5**
```
Đọc docs/AUTONOMOUS_MODE.md và Tech Spec mục 6. Làm CHỈ Milestone 6.5:
refactor mọi công cụ xây dựng và quyền thần hiện có thành Command (validate/execute/cost/describe),
thêm CommandBus (validate → trừ chi phí → execute → signal → log). UI/Tool chỉ phát Command,
không sửa state trực tiếp. Giữ nguyên hành vi hiện tại. Thêm test GUT cho validate/execute.
```

**M9b**
```
Làm CHỈ Milestone 9b. Tạo KingdomBrain, CityPlanner, EconomyManager trong src/sim/ai/ theo
docs/AUTONOMOUS_MODE.md mục 3-4. AI chỉ đọc state và phát Command qua CommandBus, mỗi tháng tối đa
N hành động (data/ai.json). Vương quốc tự chọn vị trí thành phố, mở đường, tô zone, xây hạ tầng và
nông trại, giữ quỹ dự phòng. Thêm chế độ Observer và log quyết định. Kèm script chạy headless 50 năm
báo dân số, lệnh bị từ chối, tỷ lệ xây-rồi-phá.
```

---

## 14. Mẹo vibecode

1. Agent không thấy editor: bắt nó tạo scene bằng code/`.tscn` text; việc làm tay thì bắt liệt kê từng bước.
2. Lỗi thì dán nguyên log (Output/Debugger) kèm tên file, dòng.
3. File quá 400 dòng thì bảo tách theo cấu trúc mục 3.
4. Lag: đo bằng debug overlay rồi mới tối ưu đúng hệ thống chậm nhất.
5. Thế giới "chết hết" hoặc "không có gì xảy ra": đừng sửa code ngay, chạy sim_runner nhiều seed rồi chỉnh số liệu trong `data/`.
6. Giữ commit nhỏ, đặt tên theo milestone để quay lại dễ dàng.
