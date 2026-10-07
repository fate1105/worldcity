# WORLDCITY: Godot Tech Spec (kiến trúc chuyên nghiệp)

> File này đi kèm `GDD_WorldCity.md`. **GDD = game làm gì. File này = làm bằng Godot như thế nào.** Dán cả 2 file cho AI. Nếu 2 file mâu thuẫn về công nghệ, file này thắng; về gameplay thì GDD thắng.

---

## 1. Quyết định công nghệ

| Hạng mục | Chọn | Lý do |
|---|---|---|
| Engine | **Godot 4.x (bản stable mới nhất)** | Miễn phí, nhẹ, 2D rất mạnh, xuất Android/iOS/PC/Web |
| Ngôn ngữ | **GDScript có kiểu (typed)** | AI viết tốt, nhanh để lặp. Phần nặng về sau có thể chuyển C# hoặc GDExtension |
| Renderer | **Mobile** (hoặc Compatibility cho máy yếu) | Tiết kiệm pin, chạy mượt điện thoại |
| Góc nhìn | **Top-down 2D, tile 16x16** (như WorldBox) | Dễ mở rộng bản đồ lớn, dễ đặt ô. Isometric để dành bản sau |
| Bản đồ | **TileMapLayer** (chia chunk) | API mới của Godot 4.3+, thay TileMap cũ |
| Đường đi | **AStarGrid2D** (built-in) + flow field cho đám đông | Nhanh, không cần tự viết |
| Dữ liệu | **JSON + Resource (.tres)** | Chỉnh số liệu không cần sửa code |
| Version control | **Git** | Bắt buộc. Commit sau mỗi milestone |
| Test | **GUT** (Godot Unit Test) cho logic mô phỏng | Bắt lỗi kinh tế/AI sớm |

---

## 2. Nguyên tắc kiến trúc (quan trọng nhất)

1. **Tách Mô phỏng (Simulation) khỏi Hiển thị (View).**
   Logic game nằm trong các lớp `RefCounted`/dữ liệu thuần, **không** phụ thuộc Node. Node chỉ để vẽ và nhận input. Nhờ vậy: lưu/tải dễ, test được, tối ưu được, chạy nhanh.
2. **Không dùng 1 Node cho 1 cư dân.** 1000+ Node sẽ lag điện thoại. Cư dân là **dữ liệu** (struct/PackedArray), vẽ bằng `MultiMeshInstance2D` hoặc `_draw()` theo lô.
3. **Data-driven.** Nhà, chủng tộc, trait, quyền năng, thiên tai khai báo trong file dữ liệu, code chỉ đọc.
4. **Giao tiếp bằng tín hiệu qua `EventBus`** (autoload), các hệ thống không gọi chéo nhau trực tiếp.
5. **Tick cố định + chia lô (time-slicing).** Không update mọi thứ mỗi frame.
6. **Mọi số cân bằng nằm trong dữ liệu**, không hard-code.
7. **GDScript có kiểu ở mọi nơi:** `var hp: int = 10`, `func foo(x: float) -> void`. Bật cảnh báo "untyped declaration" trong Project Settings.

---

## 3. Cấu trúc thư mục

```
worldcity/
├─ project.godot
├─ AGENTS.md                  # luật cho AI (xem mục 12)
├─ .gitignore                 # bỏ .godot/, export/
├─ data/                      # dữ liệu cân bằng (JSON)
│  ├─ buildings.json
│  ├─ races.json
│  ├─ traits.json
│  ├─ powers.json
│  ├─ disasters.json
│  ├─ events.json
│  ├─ terrain.json
│  └─ balance.json
├─ src/
│  ├─ autoload/               # singleton toàn cục
│  │  ├─ event_bus.gd
│  │  ├─ game_clock.gd
│  │  ├─ data_db.gd           # nạp JSON, tra cứu
│  │  ├─ save_system.gd
│  │  └─ settings.gd
│  ├─ sim/                    # LOGIC THUẦN, không Node
│  │  ├─ world_state.gd       # toàn bộ state, tuần tự hóa được
│  │  ├─ world_gen.gd         # noise → địa hình
│  │  ├─ tile_grid.gd         # PackedArray theo layer
│  │  ├─ citizens/            # citizen_store, citizen_ai, needs, lifecycle
│  │  ├─ city/                # zoning, demand, buildings, utilities, economy
│  │  ├─ kingdoms/            # kingdom, borders, diplomacy, kingdom_ai
│  │  ├─ war/                 # armies, combat, siege
│  │  ├─ powers/              # god powers
│  │  ├─ events/              # disasters, event_director
│  │  └─ scheduler.gd         # tick + time-slicing
│  ├─ view/                   # HIỂN THỊ
│  │  ├─ world_view.tscn/.gd  # TileMapLayer chunks
│  │  ├─ citizen_renderer.gd  # MultiMesh
│  │  ├─ camera_controller.gd
│  │  ├─ overlays/            # điện, nước, ô nhiễm, biên giới
│  │  └─ fx/                  # lửa, mưa, nổ
│  ├─ ui/                     # HUD, toolbar, panels, popup, minimap
│  └─ tools/                  # brush, zone_tool, road_tool, power_tool
├─ assets/
│  ├─ tilesets/ sprites/ audio/ fonts/ shaders/
├─ scenes/
│  ├─ main.tscn  main_menu.tscn  game.tscn
└─ tests/                     # GUT
```

---

## 4. Autoload (singleton)

| Tên | Việc |
|---|---|
| `EventBus` | Chứa toàn bộ signal: `citizen_died(id)`, `war_declared(a,b)`, `month_passed`, `building_placed(...)`, `power_used(...)`... |
| `GameClock` | Quản lý tick, tốc độ (0/1/2/5x), ngày/tháng/năm, phát signal `tick`, `day_passed`, `month_passed`, `year_passed` |
| `DataDB` | Nạp mọi JSON lúc khởi động, cung cấp `DataDB.building("house_1")`, kiểm tra lỗi dữ liệu |
| `SaveSystem` | Lưu/tải `WorldState`, có số phiên bản, nén |
| `Settings` | Cài đặt người chơi, lưu `user://settings.cfg` |

---

## 5. Lưu trữ dữ liệu mô phỏng (hiệu năng)

**Lưới ô**, mỗi layer 1 `PackedArray` kích thước `W*H`, truy cập `idx = y*W + x`:
```gdscript
var terrain: PackedByteArray     # loại ô
var height: PackedByteArray
var fertility: PackedByteArray
var owner_id: PackedInt32Array   # id vương quốc
var building_id: PackedInt32Array
var road: PackedByteArray
var power: PackedByteArray
var water: PackedByteArray
var pollution: PackedByteArray
var happiness_map: PackedByteArray
```

**Cư dân dạng SoA (structure of arrays)** để nhanh và dễ lưu:
```gdscript
class_name CitizenStore
var count: int
var alive: PackedByteArray
var pos_x: PackedFloat32Array
var pos_y: PackedFloat32Array
var age: PackedInt32Array
var hunger: PackedByteArray
var happiness: PackedByteArray
var race: PackedByteArray
var kingdom: PackedInt32Array
var home: PackedInt32Array
var job: PackedInt32Array
var state: PackedByteArray       # enum AIState
var traits: Array                # mảng nhỏ bitmask
# id = chỉ số mảng; dùng free-list tái sử dụng slot
```
(Nếu AI thấy SoA khó cho giai đoạn đầu, cho phép dùng `class Citizen extends RefCounted` rồi **refactor sang SoA ở Milestone 11**. Đừng dùng Node.)

**Công trình, vương quốc, quân đội**: `RefCounted`/`Resource` thông thường, số lượng ít hơn nhiều.

---

## 6. Tick và Scheduler

- `GameClock` chạy `_physics_process` với tick cố định **10 tick/giây** ở x1 (nhân theo tốc độ, giới hạn số tick tối đa mỗi frame để không treo).
- Phân tầng:

| Tần suất | Việc |
|---|---|
| Mỗi tick | Di chuyển cư dân/quân, va chạm, chiến đấu, lửa lan, hiệu ứng |
| Mỗi ngày (100 tick) | Nhu cầu cá nhân, mọc nhà, tính điện/nước, ô nhiễm |
| Mỗi tháng | Kinh tế, sinh sản, thuế, ngoại giao, AI vương quốc, sự kiện |
| Mỗi năm | Lão hóa, thống kê, kiểm tra thành tựu |

- **Time-slicing:** cư dân chia 10 nhóm; tick thứ `n` chỉ xử lý nhóm `n % 10`. Có ngân sách thời gian mỗi frame (vd 4 ms); hết ngân sách thì để dành cho frame sau.
- **Tìm đường:** hàng đợi yêu cầu, tối đa K yêu cầu/tick, kết quả cache theo cặp vùng.
- Lưu ý **RNG có seed** (`RandomNumberGenerator` với `seed` lưu trong state) để tái hiện lỗi và lưu/tải chuẩn.

---

## 7. Hiển thị

- **Địa hình:** `TileMapLayer` chia chunk 32x32; chỉ cập nhật chunk bị đổi (dirty flag), chỉ bật chunk trong khung nhìn.
- **Cư dân/quân:** `MultiMeshInstance2D` (1 draw call cho hàng nghìn sprite), cập nhật vị trí theo lô; chỉ vẽ trong camera.
- **Công trình:** sprite theo ô, gom vào `TileMapLayer` riêng hoặc MultiMesh.
- **Camera2D:** kéo, chụm 2 ngón zoom (`InputEventMagnifyGesture`/`InputEventScreenDrag`), giới hạn biên, zoom mượt.
- **Overlay** (điện, nước, hạnh phúc, biên giới): vẽ bằng `Image` → `ImageTexture` hoặc shader, phủ lên bản đồ.
- **Biên giới vương quốc:** shader hoặc texture từ `owner_id`.
- **Hiệu ứng:** `GPUParticles2D`/`CPUParticles2D` (Compatibility renderer nên dùng CPU).
- **Giai đoạn đầu dùng placeholder** (ô màu, hình vuông/tròn). Pixel art thay sau ở Milestone 12.

---

## 8. Input và UI

- Bọc input trong lớp `InputRouter` hỗ trợ **chuột + cảm ứng**; các công cụ (`brush`, `zone_tool`, `road_tool`...) kế thừa 1 lớp `Tool` với `begin/update/end`.
- UI dùng `Control` + `Theme` thống nhất; **responsive** theo kích thước màn hình (Container, anchor), nút to cho ngón tay (≥ 48px).
- Khung HUD, thanh công cụ dưới, bảng thông tin, minimap, nhật ký sự kiện, popup lựa chọn.
- Dùng **signal** từ `EventBus` để UI tự cập nhật, UI không đọc state mỗi frame.
- Chuỗi dịch: dùng `tr()` và file CSV dịch ngay từ đầu (Tiếng Việt + Tiếng Anh).

---

## 9. Dữ liệu mẫu (JSON)

`data/buildings.json`
```json
{
  "house_1": {
    "name_key": "BLDG_HOUSE_1", "zone": "R", "level": 1,
    "capacity": 4, "cost": 20, "upkeep": 1, "tax": 6,
    "needs": {"power": false, "water": false},
    "size": [1,1], "sprite": "house_1"
  },
  "farm": {
    "zone": "I", "workers": 3, "output": {"food": 12},
    "terrain_ok": ["grass"], "cost": 40, "upkeep": 1
  }
}
```

`data/powers.json`
```json
{
  "lightning": {"mana": 15, "radius": 1, "effect": "damage", "damage": 50, "ignite": 0.3},
  "rain": {"mana": 10, "radius": 4, "effect": "rain", "duration": 200}
}
```

`data/races.json`
```json
{
  "human": {"lifespan": 70, "birth_rate": 1.0, "attack": 1.0, "like": ["grass"], "color": "#e0b080"},
  "elf":   {"lifespan": 200, "birth_rate": 0.4, "attack": 1.0, "like": ["forest"], "color": "#90e090"}
}
```

`DataDB` phải **kiểm tra schema** và báo lỗi rõ khi thiếu trường.

---

## 10. Lưu / Tải

- `WorldState.to_dict()` / `from_dict()`; các `Packed*Array` lưu thẳng (nhị phân) hoặc nén (`FileAccess.COMPRESSION_ZSTD`).
- File lưu có `save_version`; mỗi khi đổi cấu trúc thì thêm hàm **migrate**.
- Lưu ở `user://saves/slot_N.sav`, có **autosave** mỗi năm game.
- Kiểm tra toàn vẹn: tải xong chạy `validate()` (id trỏ đúng, không âm...).

---

## 11. Xuất bản, hiệu năng, chất lượng

- **Mục tiêu hiệu năng:** 60 FPS với 1000 cư dân và bản đồ 128x128 trên điện thoại tầm trung; 30 FPS ở 3000 cư dân.
- **Debug overlay:** FPS, số cư dân, thời gian mỗi hệ thống (ms), số yêu cầu tìm đường. Dùng `Time.get_ticks_usec()` đo từng hệ thống.
- **Profile** bằng Godot Profiler/Monitors trước khi tối ưu; không tối ưu mù.
- **Android:** cài Android Build Template + JDK + SDK, tạo Export Preset, bật `Use Gradle Build`; ký APK/AAB bằng keystore.
- **Test (GUT):** kinh tế cân bằng, demand, A*, save/load khứ hồi, quan hệ ngoại giao, tính tất định theo seed.
- **Chế độ headless**: chạy mô phỏng 100 năm không hình để bắt crash/nghẽn (`godot --headless`).
- **CI (tùy chọn):** GitHub Actions chạy GUT mỗi lần push.

---

## 12. Luật cho AI (đặt vào `AGENTS.md` ở thư mục gốc)

```
# Luật dự án WorldCity
- Engine: Godot 4.x, GDScript có kiểu. Không dùng API đã lỗi thời của Godot 3.
- Logic mô phỏng đặt trong src/sim, KHÔNG phụ thuộc Node/SceneTree.
- Hiển thị đặt trong src/view và src/ui. View chỉ đọc state, không sửa logic.
- Không tạo 1 Node cho mỗi cư dân. Dùng CitizenStore + MultiMesh.
- Mọi số liệu cân bằng nằm trong data/*.json. Không hard-code số.
- Giao tiếp giữa hệ thống qua EventBus signal.
- Dùng AStarGrid2D cho tìm đường. Dùng PackedArray cho dữ liệu lưới.
- RNG phải có seed, lưu trong WorldState.
- Mỗi tính năng mới: giữ nguyên tính năng cũ, thêm test GUT nếu có logic.
- Ưu tiên tạo scene bằng code hoặc file .tscn dạng text rõ ràng, tránh phụ thuộc thao tác chuột trong editor.
- Chỉ làm đúng milestone được yêu cầu. Không tự thêm tính năng.
- Sau khi sửa, tự chạy thử bằng `godot --headless` nếu có thể và báo lỗi nếu có.
```

---

## 13. Lộ trình Milestone (tương ứng GDD, nhưng theo kiến trúc Godot)

Mỗi milestone: chạy được, commit Git, rồi mới làm tiếp.

| # | Milestone | Kết quả cần có |
|---|---|---|
| 0 | **Khởi tạo dự án** | Project Godot, cấu trúc thư mục, autoload rỗng, `AGENTS.md`, `.gitignore`, Git init, scene chính chạy được |
| 1 | **Thế giới + camera** | `TileGrid`, `WorldGen` (noise), `TileMapLayer` chia chunk, camera kéo/zoom (chuột + cảm ứng), debug overlay FPS |
| 2 | **Clock + scheduler + data** | `GameClock`, nút tốc độ, `DataDB` đọc JSON, `EventBus`, HUD ngày/tháng/năm |
| 3 | **God mode: cọ + quyền năng** | Công cụ cọ vẽ địa hình, mana, mưa/sét/lửa/núi lửa, hiệu ứng, lửa lan |
| 4 | **Cư dân cơ bản** | `CitizenStore`, spawn bằng chuột, đi lại, đói, ăn, tuổi, chết, MultiMesh, bấm xem thông tin |
| 5 | **Đường đi** | `AStarGrid2D`, hàng đợi tìm đường, đường xá tăng tốc độ |
| 6 | **Xây dựng + khu vực** | Công cụ đường, zone R/C/I, điện, nước, demand, nhà tự mọc, nâng cấp, overlay |
| 7 | **Việc làm + kinh tế** | Nhà/việc/nông trại, thuế, chi phí, thức ăn, đói, HUD tài nguyên, ngân sách |
| 8 | **Chủng tộc, trait, sinh sản** | Load từ JSON, thừa hưởng trait, ban phước/nguyền rủa |
| 9 | **Vương quốc + biên giới** | Thành lập, màu cờ, biên giới shader, minimap, AI vương quốc |
| 10 | **Ngoại giao + chiến tranh** | Quan hệ, giao thương, liên minh, tuyên chiến, lính, giao tranh, chiếm thành |
| 11 | **Thiên tai + sự kiện + log** | `EventDirector`, sự kiện lựa chọn, nhật ký |
| 12 | **Lưu/Tải + tối ưu** | `SaveSystem`, migrate, refactor SoA nếu chưa, profile, time-slicing đầy đủ |
| 13 | **Nghệ thuật + âm thanh** | Thay placeholder bằng pixel art, nhạc, SFX, shader nước |
| 14 | **Đóng gói** | Export Android/PC, menu chính, cài đặt, dịch, icon, test thiết bị thật |

### Prompt mẫu cho Milestone 0

```
Đọc GDD_WorldCity.md và WorldCity_Godot_Tech_Spec.md.
Làm CHỈ Milestone 0: tạo project Godot 4 theo cấu trúc thư mục mục 3,
tạo các autoload rỗng (EventBus, GameClock, DataDB, SaveSystem, Settings),
file AGENTS.md theo mục 12, .gitignore chuẩn Godot, và scene main.tscn
hiển thị chữ "WorldCity" để chắc chắn project chạy được.
Giải thích cách mở project và chạy.
```

### Prompt mẫu cho Milestone 1

```
Làm CHỈ Milestone 1. Tạo TileGrid (PackedArray), WorldGen dùng FastNoiseLite
sinh bản đồ 128x128 theo loại ô trong GDD mục 2, hiển thị bằng TileMapLayer
chia chunk 32x32 (placeholder: tileset màu tạo bằng code), Camera2D kéo thả và zoom
bằng chuột và cảm ứng, overlay debug FPS. Tuân thủ AGENTS.md.
```

---

## 14. Mẹo vibecode với Godot

1. **AI không thấy editor.** Hãy cho AI sinh scene bằng code hoặc `.tscn` dạng text; những gì phải làm tay (import ảnh, đặt Autoload, Export) thì bảo AI **liệt kê từng bước** cho bạn.
2. **Lỗi thì dán nguyên log** từ panel Output/Debugger cho AI, kèm tên file và dòng.
3. Hay gặp: AI dùng API Godot 3 (`KinematicBody2D`, `onready` cũ, `TileMap` cũ). Nhắc "Godot 4.x, dùng `CharacterBody2D`, `@onready`, `TileMapLayer`".
4. **Commit trước mỗi lần nhờ AI sửa lớn** để quay lại được.
5. Khi code phình to, bảo AI **tách file** theo cấu trúc mục 3, đừng để file >500 dòng.
6. Cứ 2-3 milestone, nhờ AI **review kiến trúc** đối chiếu với mục 2 và sửa chỗ vi phạm.
7. Khi lag: đo bằng debug overlay trước, rồi mới nhờ AI tối ưu đúng hệ thống chậm nhất.
