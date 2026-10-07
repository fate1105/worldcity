# WORLDCITY: Game Design Doc (dùng để vibecode)

> Game 2D isometric/top-down: **xây thành phố kiểu TheoTown** trong **thế giới sống kiểu WorldBox**. Người chơi vừa là Thần (tạo thế giới, thả quyền năng) vừa là Thị trưởng (quy hoạch, quản lý).

---

## 0. Cách dùng file này với AI

Dán cả file vào AI coding tool (Claude Code, Cursor...), rồi ra lệnh **từng Milestone một** (xem mục 15). Đừng bảo "làm hết".

**Tech stack khuyên dùng:** HTML5 + JavaScript thuần (Canvas 2D), 1 file `index.html` + vài file JS. Lý do: không cần cài gì, mở trên điện thoại được ngay, AI viết rất tốt. Muốn nghiêm túc hơn thì chuyển sang Godot sau.

**Nguyên tắc code:** dữ liệu tách khỏi logic (mọi số liệu nằm trong `CONFIG`), mỗi hệ thống 1 module, mọi thứ chạy theo tick.

---

## 1. Core loop

1. Tạo/chỉnh địa hình (God mode)
2. Thả dân và quy hoạch khu vực (Mayor mode)
3. Dân tự sống, sinh sản, làm việc, đánh nhau
4. Thành phố phát triển thành vương quốc, va chạm với vương quốc khác
5. Sự kiện, thiên tai, chiến tranh tạo biến cố
6. Người chơi can thiệp (thưởng/phạt/xây dựng) rồi lặp lại

**Mục tiêu:** sandbox, không có thắng/thua cứng. Có "Thành tựu" và "Điểm thịnh vượng" để thấy tiến bộ.

---

## 2. Thế giới (World)

- Lưới ô vuông **128x128** (có thể chọn 64/128/256).
- Mỗi ô (`Tile`): `type`, `height`, `fertility`, `owner` (id vương quốc), `building` (id hoặc null), `road` (bool), `power`, `water`, `pollution`.

| Loại ô | Đi được | Xây được | Ghi chú |
|---|---|---|---|
| Biển sâu | Không | Không | Cần thuyền |
| Biển nông | Chậm | Không | Cá |
| Cát | Có | Có (kém) | Bãi biển |
| Đất/cỏ | Có | Có | Màu mỡ cao |
| Rừng | Chậm | Phải chặt | Gỗ |
| Núi | Rất chậm | Hầm mỏ | Đá, quặng |
| Tuyết | Chậm | Có (kém) | Lạnh, dân giảm hạnh phúc |
| Sa mạc | Có | Có (kém) | Khô, ít nước |
| Đầm lầy | Chậm | Không | Bệnh dịch dễ lây |
| Dung nham | Chết | Không | Từ núi lửa |

- **Sinh thế giới:** Perlin/Simplex noise cho `height` → ngưỡng chia biển/đất/núi; noise thứ 2 cho độ ẩm + nhiệt độ → chọn sinh thái.
- **Chu kỳ ngày/đêm + 4 mùa** (mùa ảnh hưởng nông nghiệp, hạnh phúc).

---

## 3. Chế độ Thần (God Mode)

Thanh công cụ, mỗi quyền năng có **Mana** (hồi 1/giây, tối đa 100 + nâng cấp bằng Đền thờ).

**Địa hình (miễn phí, không tốn mana):** nâng/hạ đất, vẽ biển, cát, cỏ, rừng, núi, tuyết, sa mạc; cọ to nhỏ 1-10 ô; tẩy.

**Tạo sinh vật:** người, elf, orc, dwarf, động vật (nai, sói, cá, gà).

| Quyền năng | Mana | Hiệu ứng |
|---|---|---|
| Mưa | 10 | Tăng fertility, dập lửa |
| Sét | 15 | Sát thương 1 ô, có thể gây cháy |
| Lửa | 10 | Cháy lan theo rừng/nhà |
| Động đất | 40 | Phá nhà trong bán kính 6, tạo nứt |
| Núi lửa | 60 | Tạo núi + dung nham lan |
| Bom axit | 30 | Hủy cây, nhà, gây đột biến |
| Ban phước | 20 | Thêm trait tốt cho 1 người |
| Nguyền rủa | 20 | Thêm trait xấu |
| Hồi sinh | 50 | Sống lại 1 nhân vật |
| Bệnh dịch | 35 | Lây theo tiếp xúc |
| Rồng/Quái vật | 80 | Thực thể tấn công thành phố |
| Bom nguyên tử | 100 | Phá hủy bán kính lớn, phóng xạ |

---

## 4. Chế độ Thị trưởng (Mayor Mode)

### 4.1 Công cụ xây
- **Đường:** nối các khu, tốc độ đi tăng; đường lớn (nhanh hơn, tốn tiền hơn).
- **Quy hoạch khu (zone), tô vùng rồi dân tự xây:**
  - **R (Dân cư):** nhà ở, 3 mật độ (thấp/trung/cao).
  - **C (Thương mại):** chợ, cửa hàng, quán.
  - **I (Công nghiệp):** xưởng, mỏ, nông trại.
- **Hạ tầng:** nhà máy điện (than/gió/mặt trời), tháp nước, đường dây điện (lan 6 ô từ trụ), cống.
- **Dịch vụ:** trường học, bệnh viện, cứu hỏa, lính gác (cảnh sát), công viên, đền thờ.
- **Quân sự:** trại lính, tháp canh, tường thành, cổng.
- **Đặc biệt:** bến cảng, chợ giao thương, thư viện, Pháp sư tháp.

### 4.2 Mỗi 1 ô khu vực phát triển theo "nhu cầu" (demand)
```
demandR = (jobs - population) * 0.5 + happiness_bonus
demandC = population * 0.3 - commercial_capacity
demandI = population * 0.2 - industrial_capacity
```
Nếu demand > 0 và ô có đường + điện + nước → xác suất mọc nhà mỗi tick.
Nhà nâng cấp level 1→3 khi: giá đất cao, dịch vụ đủ, ô nhiễm thấp.

### 4.3 Kinh tế
- **Tiền (Vàng)**, **Thức ăn**, **Gỗ**, **Đá**, **Quặng**, **Mana**.
- **Thu:** thuế (R/C/I riêng, chỉnh 0-20%), giao thương, cống phẩm.
- **Chi:** bảo trì công trình, lương lính, dịch vụ.
- Mỗi tháng game: `balance = thu - chi`. Âm quá 3 tháng → bất ổn, dân bỏ đi, lính đào ngũ.
- **Thức ăn:** nông trại, săn bắn, cá. Dân tiêu 1 thức ăn/người/tháng. Thiếu → đói → chết, nổi loạn.

---

## 5. Cư dân (Citizen)

**Thuộc tính:** `id, name, race, age, gender, health, hunger(0-100), happiness(0-100), job, home, workplace, kingdom, traits[], relations[], position, state`

**Vòng đời:** Sơ sinh → Trẻ em (0-14) → Trưởng thành → Già (60+) → Chết. Tuổi thọ phụ thuộc chủng tộc.

**Sinh sản:** 2 người trưởng thành khác giới, cùng nhà, hạnh phúc > 50, thức ăn đủ → xác suất có con mỗi tháng. Con thừa hưởng trait từ cha mẹ (30%).

**AI trạng thái (State machine, mỗi người):**
```
IDLE → tìm nhu cầu cao nhất:
  hunger > 70   → FIND_FOOD
  không có nhà  → FIND_HOME / BUILD_HOME
  không có việc → FIND_JOB
  ban đêm       → SLEEP
  happiness thấp→ SOCIALIZE / RELAX
  có địch gần   → FIGHT hoặc FLEE
  khác          → WORK
```
Đi đường bằng **A\*** (đường đi nhanh hơn địa hình thường). Dùng cache và giới hạn tìm đường mỗi tick để không lag.

**Nghề:** Nông dân, Thợ gỗ, Thợ mỏ, Thợ xây, Thương nhân, Lính, Giáo viên, Bác sĩ, Pháp sư, Quan chức.

---

## 6. Chủng tộc và Trait

| Chủng tộc | Ưu | Nhược | Thích địa hình |
|---|---|---|---|
| Người | Sinh sản nhanh, cân bằng | Không nổi trội | Đồng bằng |
| Elf | Sống lâu, phép, cung | Sinh sản chậm | Rừng |
| Orc | Mạnh, chiến đấu | Dễ gây chiến, hạnh phúc thấp | Đồi/núi |
| Dwarf | Đào mỏ, thợ giỏi | Chậm, ghét biển | Núi |

**Trait (mỗi người 0-3 trait):**
- Tốt: Chăm chỉ, Thông minh, Dũng cảm, Khỏe mạnh, May mắn, Lãnh đạo
- Xấu: Lười, Hèn, Dễ ốm, Tham lam, Hung hãn, Bất hạnh
- Đặc biệt: Đột biến (từ axit), Bị nguyền, Được ban phước, Bất tử (hiếm)

Mỗi trait = modifier số (vd Chăm chỉ: +20% năng suất).

---

## 7. Vương quốc và Chính trị

- **Thành lập:** 1 thành phố đủ dân (≥ 30 người) + có Lãnh đạo → thành **Vương quốc** có tên, màu cờ, biên giới (tô màu `owner` các ô xung quanh).
- **Biên giới:** mở rộng theo công trình và dân. Chồng lấn → xung đột.
- **Người chơi** điều khiển 1 vương quốc chính; các vương quốc khác chạy AI.

**Quan hệ ngoại giao (-100 đến +100):**
- Tăng: giao thương, đồng minh, cùng chủng tộc, quà tặng.
- Giảm: tranh chấp biên giới, khác chủng tộc, cướp bóc, bị tuyên chiến.
- Ngưỡng: < -60 có thể tuyên chiến; > +60 có thể kết đồng minh; > +30 giao thương.

**Hành động ngoại giao:** Gửi quà, Giao thương, Liên minh, Tuyên chiến, Đình chiến, Cống nạp.

**AI vương quốc ra quyết định mỗi tháng** theo "tính cách" (Hiếu chiến / Hòa bình / Thương mại / Khép kín):
```
nếu mạnh hơn láng giềng 1.5x và hiếu chiến → tuyên chiến
nếu thiếu thức ăn → giao thương hoặc cướp
nếu bị đe dọa → xin liên minh
```

**Nổi loạn:** nếu happiness trung bình < 30 trong 3 tháng → thành phố ly khai thành vương quốc mới.

---

## 8. Chiến tranh

- **Lính:** Kiếm sĩ, Cung thủ, Kỵ binh, Pháp sư, Công thành. Có `attack, defense, hp, speed, range`.
- **Chiến đấu:** 2 bên trong bán kính tấn công → trừ HP = `attack - defense*0.5` (+ ngẫu nhiên ±20%). Địa hình/tường thành/ trait ảnh hưởng.
- **Quy trình:** Tuyên chiến → huy động lính → tiến về thành địch → bao vây → chiếm (đổi `owner`) hoặc đình chiến.
- **Hậu quả:** nhà bị phá, dân chạy loạn, tử trận làm hạnh phúc giảm toàn vương quốc.
- **Chế độ nhanh:** cho phép thu nhỏ tính toán (chiến đấu theo nhóm) khi quá đông.

---

## 9. Thiên tai và Sự kiện

**Tự động ngẫu nhiên** (tần suất chỉnh trong cài đặt: Tắt / Ít / Vừa / Nhiều):
Cháy rừng, Hạn hán, Lũ, Bão, Động đất, Dịch bệnh, Châu chấu, Quái vật, Sao chổi.

**Sự kiện tốt:** Mùa màng bội thu, Phát hiện mỏ, Anh hùng ra đời, Thương đoàn ghé qua.

**Sự kiện lựa chọn:** popup 2 lựa chọn (vd: "Lãnh chúa xin cống nạp: Đưa 100 vàng / Từ chối"), mỗi lựa chọn có hậu quả khác nhau.

**Công nghệ/Tôn giáo (tùy chọn, làm sau):** Cây công nghệ 5 cấp (Đá → Đồng → Sắt → Thép → Ma thuật), mở khóa công trình. Tôn giáo lan truyền giữa dân, ảnh hưởng hạnh phúc và quan hệ.

---

## 10. Hệ thống mô phỏng (Simulation)

- **Tick:** 10 tick/giây ở tốc độ x1. Nút tốc độ: Tạm dừng / x1 / x2 / x5.
- **Thời gian game:** 1 ngày = 100 tick; 1 tháng = 30 ngày; 1 năm = 12 tháng.
- **Phân tầng cập nhật (tối ưu):**
  - Mỗi tick: di chuyển, chiến đấu, hiệu ứng.
  - Mỗi ngày: nhu cầu cá nhân, mọc nhà, cháy lan.
  - Mỗi tháng: kinh tế, sinh sản, ngoại giao, AI vương quốc.
- **Hiệu năng:** chỉ vẽ ô trong khung nhìn; xử lý dân theo lô (chia nhóm, mỗi tick xử lý 1/10 số dân); mục tiêu 1000+ dân mượt trên điện thoại.
- **Lưu/Tải:** serialize toàn bộ state ra JSON, lưu `localStorage` (hoặc file tải về).

---

## 11. Giao diện (UI/UX), ưu tiên mobile

- **Thanh dưới:** tab `Địa hình | Sinh vật | Quyền năng | Xây dựng | Khu vực | Ngoại giao`.
- **Thanh trên:** Tiền, Thức ăn, Gỗ, Đá, Mana, Dân số, Ngày/Tháng/Năm, nút tốc độ.
- **Camera:** kéo để di chuyển, chụm 2 ngón/lăn chuột để zoom.
- **Bấm vào 1 người/công trình:** hiện bảng thông tin (tên, trait, nhu cầu, quan hệ).
- **Bản đồ nhỏ (minimap)** hiện biên giới màu từng vương quốc.
- **Chế độ xem (overlay):** Điện, Nước, Ô nhiễm, Hạnh phúc, Biên giới, Mật độ dân.
- **Nhật ký sự kiện (log)** cuộn: "Năm 12: Vương quốc Ardan tuyên chiến với Gorak."
- **Cài đặt:** tốc độ, tần suất thiên tai, bật/tắt âm, độ khó.

**Phong cách hình ảnh:** pixel art đơn giản, màu tươi. Giai đoạn đầu dùng **hình khối màu** (hình vuông/tròn) thay vì sprite, thay hình sau.

---

## 12. Cấu trúc dữ liệu gợi ý

```js
const CONFIG = { mapSize:128, tickRate:10, ticksPerDay:100, ... };

state = {
  tiles: Tile[][],
  citizens: Map<id, Citizen>,
  buildings: Map<id, Building>,
  kingdoms: Map<id, Kingdom>,
  armies: [], monsters: [],
  time: {tick, day, month, year},
  resources: { gold, food, wood, stone, mana },
  settings: {...}, log: []
};

Kingdom = { id, name, color, race, capital, treasury, relations:{kid:score},
            personality, atWar:[kid], allies:[kid] }
Building = { id, type, x, y, level, kingdom, workers:[], hp, needs:{power,water} }
```

---

## 13. Cân bằng (giá trị khởi đầu, chỉnh sau)

- Mana hồi 1/giây, tối đa 100. Vàng khởi đầu 1000. Thức ăn khởi đầu 200.
- Nhà cấp 1: chứa 4 người, chi phí bảo trì 1 vàng/tháng. Thuế 5-10 vàng/tháng/nhà.
- Dân tiêu 1 thức ăn/tháng. Nông trại ra 12 thức ăn/tháng/người làm.
- Lính lương 3 vàng/tháng. Tháp canh 50 vàng.
- Tất cả để trong `CONFIG` để dễ chỉnh.

---

## 14. Ngoài phạm vi bản đầu (để sau)

Multiplayer, mod/plugin, tôn giáo chi tiết, cây công nghệ đầy đủ, cốt truyện, âm nhạc động, bản đồ vô hạn.

---

## 15. Lộ trình vibecode (làm từng Milestone, mỗi cái chạy được rồi mới sang cái tiếp)

| # | Milestone | Prompt mẫu cho AI |
|---|---|---|
| 1 | **Bản đồ + camera** | "Tạo game HTML5 Canvas, bản đồ 128x128 sinh bằng noise, các loại ô theo mục 2, kéo để di chuyển, zoom, có cọ vẽ địa hình." |
| 2 | **God mode cơ bản** | "Thêm thanh công cụ, mana, quyền năng: mưa, sét, lửa, núi lửa theo mục 3." |
| 3 | **Dân đơn giản** | "Thêm citizen: sinh ra, đi lại ngẫu nhiên bằng A*, đói, ăn, chết, tuổi. Bấm vào xem thông tin." |
| 4 | **Xây dựng + khu vực** | "Thêm đường, zone R/C/I, điện/nước, nhà tự mọc theo demand (mục 4)." |
| 5 | **Việc làm + kinh tế** | "Dân có nhà, có việc, tiền thu/chi hàng tháng, thức ăn, thuế (mục 4.3, 5)." |
| 6 | **Chủng tộc + trait + sinh sản** | "Thêm 4 chủng tộc, trait, sinh con thừa hưởng trait (mục 5, 6)." |
| 7 | **Vương quốc** | "Thêm vương quốc, biên giới màu, minimap, AI vương quốc láng giềng (mục 7)." |
| 8 | **Ngoại giao + chiến tranh** | "Thêm quan hệ, giao thương, liên minh, tuyên chiến, lính, chiến đấu (mục 7, 8)." |
| 9 | **Thiên tai + sự kiện** | "Thêm thiên tai ngẫu nhiên, sự kiện lựa chọn, nhật ký (mục 9)." |
| 10 | **Hoàn thiện** | "Lưu/tải game, overlay, cài đặt, tối ưu hiệu năng cho mobile, thay hình khối bằng sprite pixel." |

### Mẹo vibecode
1. **Mỗi lần chỉ 1 milestone**, test xong mới đi tiếp. Lỗi thì dán lỗi (console) cho AI sửa.
2. Luôn nhắc AI: *"Giữ nguyên các tính năng cũ, chỉ thêm tính năng mới, đặt số liệu vào CONFIG."*
3. Khi file quá dài, yêu cầu AI **tách module** (`world.js`, `citizen.js`, `kingdom.js`, `ui.js`).
4. Khi lag: bảo AI "profile và tối ưu vòng lặp cập nhật dân, xử lý theo lô".
5. Giữ 1 bản sao lưu (git hoặc copy file) trước mỗi milestone.
