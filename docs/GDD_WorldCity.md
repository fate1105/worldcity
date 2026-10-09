# WORLDCITY: Game Design Document (v2, hướng quan sát & tự vận hành)

> **Gameplay nằm ở file này.** Kiến trúc kỹ thuật: `WorldCity_Godot_Tech_Spec.md`. Thiết kế AI tự vận hành: `AUTONOMOUS_MODE.md`.
> Mâu thuẫn: gameplay theo GDD, công nghệ theo Tech Spec, lộ trình milestone và vai trò người chơi theo Tech Spec mục 13 và AUTONOMOUS_MODE.

---

## 0. Tầm nhìn

WorldCity là game 2D top-down: **một thế giới sống tự vận hành**, trong đó các vương quốc tự lập, tự xây thành phố, tự quản lý kinh tế, ngoại giao, chiến tranh. Người chơi chủ yếu **quan sát** thế giới phát triển từ vài người đầu tiên đến đế chế (hoặc sụp đổ), và có thể tùy chọn can thiệp như một vị thần.

Lấy cảm hứng: WorldBox (thế giới sinh vật, quyền năng thần thánh), TheoTown (quy hoạch khu R/C/I, hạ tầng, dịch vụ), Dwarf Fortress (lịch sử tự sinh).

### 3 trụ cột thiết kế
1. **Thế giới tự chạy và luôn có chuyện để xem.** Không cần người chơi bấm gì vẫn phát triển, xung đột, sụp đổ, hồi sinh.
2. **Câu chuyện nảy sinh từ luật, không viết sẵn.** Nhân vật có tên, trait, gia phả; sự kiện được ghi thành lịch sử.
3. **Thần là tùy chọn, mang tính chơi đùa.** Can thiệp thỉnh thoảng thì vui, nhưng game không bao giờ đòi hỏi.

---

## 1. Chế độ chơi

| Chế độ | Mô tả |
|---|---|
| **Observer** (mặc định) | Mọi vương quốc do AI quản lý. Người chơi chỉ chọn tốc độ, camera, xem thông tin |
| **God** | Observer + dùng quyền năng (mưa, sét, ban phước, thiên tai...) tốn Mana |
| **Mayor** | Người chơi tự điều khiển 1 vương quốc (xây, quy hoạch, thuế, ngoại giao), phần còn lại AI. Đổi qua lại được lúc đang chơi |

Cả người chơi và AI **chơi theo cùng luật** (cùng chi phí, tài nguyên, giới hạn). AI không gian lận.

### Tạo thế giới (màn hình đầu)
Kích thước (64/128/256), seed, số vương quốc khởi đầu (1-8), chủng tộc, mức thiên tai (Tắt/Ít/Vừa/Nhiều), mức hiếu chiến chung, chế độ chơi.

---

## 2. Vòng lặp cốt lõi

1. Thế giới sinh ra (hoặc người chơi chỉnh địa hình bằng cọ).
2. Nhóm cư dân đầu tiên xuất hiện → thành lập làng → thành phố → vương quốc.
3. AI mỗi vương quốc: quy hoạch, xây dựng, giữ kinh tế, nuôi quân, ngoại giao.
4. Cư dân sống: ăn, ngủ, làm việc, sinh sản, già, chết, di cư, đánh nhau.
5. Biến cố (thiên tai, dịch bệnh, anh hùng, phản loạn, chiến tranh) tạo bước ngoặt.
6. Mọi thứ ghi vào **Chronicle** (nhật ký lịch sử). Người xem theo dõi, camera tự bay tới sự kiện lớn.
7. Lặp lại qua nhiều thế hệ.

**Không có thắng/thua cứng.** Có thống kê, thành tựu, "Kỷ nguyên" (đặt tên theo biến cố lớn).

---

## 3. Thế giới

- Lưới ô vuông (mặc định **128x128**), mỗi ô 16 px.
- Thuộc tính ô: `terrain, height, fertility, owner(kingdom), building, road, power, water, pollution, happiness`.

| Địa hình | Đi được | Xây được | Ghi chú |
|---|---|---|---|
| Biển sâu | Không | Không | Cần thuyền |
| Biển nông | Chậm | Không | Cá |
| Cát | Có | Có (kém) | Bãi biển |
| Cỏ/đồng bằng | Có | Có | Màu mỡ cao |
| Rừng | Chậm | Phải chặt | Gỗ |
| Núi | Rất chậm | Hầm mỏ | Đá, quặng |
| Tuyết | Chậm | Có (kém) | Hạnh phúc -10 |
| Sa mạc | Có | Có (kém) | Khô, ít màu mỡ |
| Đầm lầy | Chậm | Không | Bệnh dịch dễ lây |
| Dung nham | Chết | Không | Từ núi lửa |

- **Sinh thế giới:** noise cho độ cao, noise thứ hai cho độ ẩm/nhiệt độ → chọn sinh thái. Đảm bảo có đủ đất trồng và nước cho các điểm khởi đầu.
- **Ngày/đêm và 4 mùa:** mùa ảnh hưởng nông nghiệp, hạnh phúc, di chuyển, bệnh tật.
- Số liệu địa hình: `data/terrain.json`.

---

## 4. Cư dân

**Thuộc tính:** `id, name, race, gender, age, health, hunger(0-100), happiness(0-100), job, home, workplace, kingdom, traits[], relations[], position, state, family(cha/mẹ/con/bạn đời)`.

**Vòng đời:** Sơ sinh → Trẻ (0-14) → Trưởng thành → Già (60+) → Chết. Tuổi thọ theo chủng tộc.

**Sinh sản:** 2 người trưởng thành, cùng nhà, hạnh phúc > 50, thức ăn đủ → xác suất sinh con mỗi tháng. Con thừa hưởng trait cha mẹ (30%), ghi gia phả.

**AI cá nhân (máy trạng thái):** chọn nhu cầu cấp bách nhất:
```
có địch gần         → FIGHT hoặc FLEE
hunger > 70         → FIND_FOOD
không có nhà        → FIND_HOME
không có việc       → FIND_JOB
ban đêm             → SLEEP
happiness thấp      → SOCIALIZE / RELAX
khác                → WORK
```
Di chuyển bằng A* (đường xá tăng tốc).

**Nghề:** Nông dân, Thợ gỗ, Thợ mỏ, Thợ xây, Thương nhân, Lính, Giáo viên, Bác sĩ, Pháp sư, Quan chức.

**Người nổi bật:** cư dân có trait đặc biệt hoặc làm nên chuyện (thắng trận, xây kỳ quan) trở thành **Nhân vật lịch sử**: được ghi vào Chronicle, camera có thể bám theo.

---

## 5. Chủng tộc và Trait

| Chủng tộc | Ưu | Nhược | Thích |
|---|---|---|---|
| Người | Sinh sản nhanh, cân bằng | Không nổi trội | Đồng bằng |
| Elf | Sống lâu, phép, cung | Sinh sản chậm, mong manh | Rừng |
| Orc | Mạnh, chiến đấu | Dễ gây chiến, hạnh phúc nền thấp | Núi, sa mạc |
| Dwarf | Đào mỏ, thợ giỏi, phòng thủ | Chậm, ghét biển | Núi |

**Trait (0-3/người):**
- Tốt: Chăm chỉ, Thông minh, Dũng cảm, Khỏe mạnh, May mắn, Lãnh đạo.
- Xấu: Lười, Hèn, Dễ ốm, Tham lam, Hung hãn, Bất hạnh.
- Đặc biệt: Đột biến, Bị nguyền, Được ban phước, Bất tử (cực hiếm).

Mỗi trait là modifier số. Chi tiết trong `data/races.json`, `data/traits.json`.

---

## 6. Thành phố

### 6.1 Quy hoạch (do AI hoặc Mayor)
- **Đường:** nối các khu; đường lớn nhanh và đắt hơn.
- **Zone:** **R** (dân cư, 3 mật độ), **C** (thương mại), **I** (công nghiệp: nông trại, mỏ, xưởng).
- **Hạ tầng:** điện (than/gió), nước (tháp nước), phủ trong bán kính.
- **Dịch vụ:** trường, bệnh viện, cứu hỏa, lính gác, công viên, đền thờ.
- **Quân sự:** trại lính, tháp canh, tường thành, cổng.
- **Đặc biệt:** cảng, chợ giao thương, thư viện, tháp pháp sư, kỳ quan.

### 6.2 Nhà tự mọc và nâng cấp
```
demandR = (jobs - population) * 0.5 + happiness_bonus
demandC = population * 0.3 - commercial_capacity
demandI = population * 0.2 - industrial_capacity
```
Ô zone có đường + điện + nước và demand > 0 → xác suất mọc nhà mỗi ngày. Nhà lên cấp 1→3 khi dịch vụ đủ, giá đất cao, ô nhiễm thấp.

### 6.3 Thất bại của thành phố
Thiếu thức ăn, nợ, ô nhiễm, tội phạm, dịch → dân bỏ đi. Thành phố có thể **suy tàn thành làng**, **bị bỏ hoang** (hoang tàn còn lại trên bản đồ), hoặc **ly khai**.

Danh mục công trình: `data/buildings.json`.

---

## 7. Kinh tế

- **Tài nguyên:** Vàng, Thức ăn, Gỗ, Đá, Quặng, Mana (quyền thần).
- **Thu:** thuế R/C/I (0-20%), giao thương, cống nạp, cướp bóc.
- **Chi:** bảo trì công trình, lương lính, dịch vụ.
- **Hàng tháng:** `balance = thu - chi`. Âm quá 3 tháng → bất ổn, lính đào ngũ, dân bỏ đi.
- **Thức ăn:** 1/người/tháng. Thiếu → đói → chết, nổi loạn, di cư, chiến tranh cướp lương.
- **Thương mại:** vương quốc có cảng/chợ giao thương trao đổi tài nguyên dư thừa, quan hệ tốt hơn.

---

## 8. Vương quốc và Chính trị

- **Thành lập:** thành phố đủ dân (≥ 30) và có Lãnh đạo → Vương quốc (tên, màu cờ, thủ đô, biên giới).
- **Biên giới:** mở rộng theo công trình, dân, đường. Chồng lấn → xung đột.
- **Lãnh đạo và kế vị:** vua/nữ hoàng có trait ảnh hưởng chính sách. Chết → con cái hoặc người giỏi nhất kế vị, có xác suất tranh ngôi/nội chiến.
- **Tính cách vương quốc:** Kiến thiết, Hiếu chiến, Thương gia, Khép kín, Tín đồ (chi tiết ở AUTONOMOUS_MODE).
- **Quan hệ (-100..+100):** tăng nhờ giao thương, đồng minh, cùng chủng tộc, quà tặng; giảm do tranh chấp biên giới, khác chủng tộc, cướp bóc, bị tuyên chiến.
- **Ngưỡng:** < -60 có thể tuyên chiến, > +30 giao thương, > +60 liên minh.
- **Hành động ngoại giao:** Quà tặng, Giao thương, Liên minh, Tuyên chiến, Đình chiến, Cống nạp.
- **Nổi loạn/ly khai:** happiness trung bình < 30 trong 3 tháng → thành phố ly khai thành vương quốc mới.
- **Diệt vong:** mất hết thành phố thì vương quốc kết thúc, ghi vào Chronicle.

---

## 9. Chiến tranh

- **Lính:** Kiếm sĩ, Cung thủ, Kỵ binh, Pháp sư, Công thành (`attack, defense, hp, speed, range`).
- **Giao tranh:** trừ HP = `attack - defense * 0.5` (±20%), ảnh hưởng bởi địa hình, tường thành, trait.
- **Quy trình:** tuyên chiến → huy động → hành quân → bao vây → chiếm thành (đổi `owner`) hoặc đình chiến.
- **Hậu quả:** nhà bị phá, dân chạy loạn, tử trận giảm hạnh phúc, chiếm thành cho tài nguyên và nô dịch/hòa nhập dân.
- **Mệt mỏi chiến tranh:** thương vong và chi phí tích lũy làm AI muốn đình chiến.
- **Chế độ nhanh:** gộp giao tranh theo nhóm khi quá đông.

---

## 10. Thiên tai và Sự kiện

**Ngẫu nhiên** (theo mức người chơi chọn): cháy rừng, hạn hán, lũ, bão, động đất, dịch bệnh, châu chấu, quái vật, sao chổi. Dữ liệu: `data/disasters.json`.

**Sự kiện tốt:** mùa màng bội thu, phát hiện mỏ, anh hùng ra đời, thương đoàn ghé qua.

**Sự kiện lựa chọn:** AI vương quốc tự chọn theo tính cách; ở chế độ Mayor hiện popup cho người chơi. Dữ liệu: `data/events.json`.

**Đạo diễn kịch tính (Drama Director):** nếu thế giới quá yên 10+ năm, tăng nhẹ xác suất biến cố; nếu một vương quốc quá thống trị, tăng xác suất thiên tai/phản loạn ở đó. Giữ thế giới thú vị mà không làm giả kết quả.

**Làm sau (tùy chọn):** cây công nghệ 5 cấp (Đá → Đồng → Sắt → Thép → Ma thuật), tôn giáo lan truyền.

---

## 11. Quyền thần (chế độ God)

Mana hồi 1/giây, tối đa 100 (đền thờ tăng thêm).

**Địa hình (miễn phí):** nâng/hạ đất, vẽ biển, cát, cỏ, rừng, núi, tuyết, sa mạc; cọ 1-10 ô; tẩy.

**Tạo sinh vật:** người, elf, orc, dwarf, động vật.

| Quyền năng | Mana | Hiệu ứng |
|---|---|---|
| Mưa | 10 | Tăng màu mỡ, dập lửa |
| Sét | 15 | Sát thương 1 ô, có thể gây cháy |
| Lửa | 10 | Cháy lan theo rừng/nhà |
| Động đất | 40 | Phá nhà bán kính 6 |
| Núi lửa | 60 | Tạo núi + dung nham |
| Bom axit | 30 | Hủy cây, nhà, gây đột biến |
| Ban phước | 20 | Thêm trait tốt |
| Nguyền rủa | 20 | Thêm trait xấu |
| Hồi sinh | 50 | Sống lại 1 nhân vật |
| Bệnh dịch | 35 | Lây theo tiếp xúc |
| Rồng/Quái vật | 80 | Tấn công thành phố |
| Bom nguyên tử | 100 | Phá hủy diện rộng, phóng xạ |

Dữ liệu: `data/powers.json`. Quyền thần cũng là **Command** (có validate, ghi Chronicle với nhãn "can thiệp của thần").

---

## 12. Chế độ quan sát (UI/UX, ưu tiên mobile)

- **Camera:** kéo, zoom (chuột + cảm ứng); **Auto-Camera** tự bay tới sự kiện lớn hoặc bám nhân vật.
- **Tốc độ:** tạm dừng, x1, x2, x5, x10, x50 (x10+ giảm hiệu ứng nặng).
- **Thanh trên:** ngày/tháng/năm, tốc độ, dân số, tài nguyên của vương quốc đang chọn.
- **Panel thông tin:** bấm nhân vật/công trình/vương quốc để xem chi tiết, gia phả, lịch sử.
- **Timeline (Chronicle):** danh sách sự kiện, lọc theo vương quốc/loại, bấm để camera tới nơi.
- **Biểu đồ:** dân số, quân sự, kinh tế, lãnh thổ theo năm.
- **Bản đồ chính trị + minimap:** màu vương quốc, đường quan hệ (xanh đồng minh, đỏ chiến tranh).
- **Overlay:** điện, nước, ô nhiễm, hạnh phúc, mật độ, biên giới.
- **Toast** thông báo nhẹ; **tóm tắt thế giới** cuối mỗi thế kỷ.
- **Cài đặt:** tốc độ, thiên tai, âm thanh, ngôn ngữ (Việt/Anh).

**Phong cách hình:** pixel art đơn giản, màu tươi. Giai đoạn đầu dùng hình khối màu (placeholder).

---

## 13. Thời gian mô phỏng

- Tick: 10/giây ở x1. 1 ngày = 100 tick; 1 tháng = 30 ngày; 1 năm = 12 tháng.
- Mỗi tick: di chuyển, giao tranh, hiệu ứng. Mỗi ngày: nhu cầu cá nhân, mọc nhà, điện/nước. Mỗi tháng: kinh tế, sinh sản, ngoại giao, AI vương quốc. Mỗi năm: lão hóa, thống kê, thành tựu.
- Mục tiêu hiệu năng: 1000+ cư dân mượt trên điện thoại tầm trung.

## 14. Số liệu khởi đầu

Vàng 1000, Thức ăn 200, Gỗ 50, Đá 20, Mana 100. Nhà cấp 1 chứa 4 người, thuế 6 vàng/tháng. Nông trại 12 thức ăn/tháng/người làm. Tất cả trong `data/balance.json`, chỉnh ở đó.

## 15. Ngoài phạm vi bản đầu

Multiplayer, mod/plugin, cây công nghệ đầy đủ, tôn giáo chi tiết, cốt truyện, nhạc động, bản đồ vô hạn.
