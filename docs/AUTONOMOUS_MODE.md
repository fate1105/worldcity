# WORLDCITY: Chế độ Tự vận hành (v2)

> Thiết kế AI để các vương quốc **tự xây dựng và tự quản lý**. Gameplay: `GDD_WorldCity.md`. Kiến trúc: `WorldCity_Godot_Tech_Spec.md` (Command ở mục 6, milestone ở mục 13).
> Số liệu AI nằm ở `data/ai.json`. Không hard-code trong `.gd`.

---

## 1. Mục tiêu

- Người chơi ngồi xem, thế giới tự phát triển từ vài người đến đế chế (hoặc sụp đổ), luôn có chuyện để xem.
- AI chơi **cùng luật** với người chơi (cùng chi phí, tài nguyên, giới hạn). Không gian lận.
- Mỗi vương quốc **khác nhau** (tính cách, hoàn cảnh), không phát triển giống hệt.
- Kết quả **tái hiện được** nhờ seed RNG.

## 2. Nguyên tắc

1. AI chỉ **đọc state** và **phát Command** qua `CommandBus`. Không sửa state trực tiếp.
2. Mỗi tháng game, mỗi vương quốc có **ngân sách hành động** (mặc định tối đa 5 Command), tạo nhịp phát triển.
3. Quyết định bằng **Utility AI**: chấm điểm hành động ứng viên, chọn cao nhất mà khả thi.
4. AI có **Memory** (nhớ lệnh bị từ chối, kẻ thù, nợ ân tình, mục tiêu) để không lặp lỗi.
5. Mọi hằng số trong `data/ai.json`. Quyết định dùng RNG có seed.
6. AI chạy theo lịch và time-slicing (vương quốc nhiều thì luân phiên), không tốn thời gian mỗi frame.

## 3. Cấu trúc

```
KingdomBrain (1 cái/vương quốc)
├─ personality        # bộ trọng số + độ lệch ngẫu nhiên
├─ CityPlanner        # vị trí, đường, zone, hạ tầng, dịch vụ, mở rộng
├─ EconomyManager     # thuế, quỹ dự phòng, thức ăn, tài nguyên
├─ PopulationManager  # nhà ở, việc làm, hạnh phúc, y tế, giáo dục
├─ MilitaryAdvisor    # quân đội, phòng thủ, chiến dịch
├─ DiplomacyAdvisor   # quan hệ, liên minh, giao thương, chiến tranh, hòa
└─ Memory             # lệnh bị từ chối, kẻ thù, mục tiêu, lịch sử quyết định
```

**Vòng suy nghĩ hàng tháng:**
```
1. Quan sát: đọc "Báo cáo tình hình" (dân số, thức ăn dự báo, ngân sách, thất nghiệp, hạnh phúc, đe dọa, quan hệ)
2. Mỗi advisor sinh ra danh sách hành động ứng viên (kèm Command dự kiến)
3. Chấm điểm: score = nhu_cầu * trọng_số_tính_cách * khả_thi * (1 - phạt_nhớ)
4. Chọn top N theo điểm, bỏ lệnh không đủ tiền hoặc vi phạm validate (thử trước bằng validate)
5. Gửi Command, ghi lý do vào Memory và log debug
6. Cập nhật mục tiêu dài hạn (3-5 năm) nếu cần
```

## 4. Tính cách

Mỗi tính cách là bộ trọng số theo nhóm hành động; vương quốc nhận độ lệch ±15%. Tính cách có thể **đổi** theo biến cố.

| Tính cách | Ưu tiên | Hay làm | Điều kiện đổi |
|---|---|---|---|
| Builder (Kiến thiết) | Hạ tầng, nhà ở, dịch vụ | Mở rộng thành phố, ít chiến tranh | Bị xâm lược liên tục → Isolationist |
| Warlord (Hiếu chiến) | Quân đội, mở rộng | Tuyên chiến, chiếm thành | Thua nặng → Isolationist/Builder |
| Merchant (Thương gia) | Cảng, chợ, giao thương | Liên minh, thương mại | Bị cướp nhiều → Warlord |
| Isolationist (Khép kín) | Tường thành, tự cung cấp | Phòng thủ, ít ngoại giao | Giàu và mạnh → Builder/Merchant |
| Zealot (Tín đồ) | Đền thờ, thống nhất chủng tộc | Gây chiến khác chủng tộc/tôn giáo | Đền sụp, lãnh đạo chết |

## 5. Hành động ứng viên (catalog)

| Advisor | Hành động | Command | Khi nào chấm điểm cao |
|---|---|---|---|
| CityPlanner | Chọn vị trí thành phố mới | `FoundCity` | Hết chỗ/thiếu tài nguyên, đủ dân đi định cư |
| | Mở đường tới cụm nhà/khu công nghiệp | `PlaceRoad` | Có khu chưa nối, đường dài kém hiệu quả |
| | Tô zone R/C/I | `SetZone` | Demand R/C/I > 0 |
| | Xây trụ điện/nước | `PlaceBuilding` | Khu có nhu cầu nhưng thiếu điện/nước |
| | Xây trường/bệnh viện/cứu hỏa/công viên | `PlaceBuilding` | Dân/khu vượt ngưỡng phủ dịch vụ |
| | Phá công trình hỏng/không dùng | `Demolish` | Bỏ hoang, cháy, chiếm đất cần thiết |
| EconomyManager | Xây nông trại/lumber/mỏ | `PlaceBuilding` | Thức ăn dự báo < nhu cầu 3 tháng; thiếu gỗ/đá |
| | Chỉnh thuế | `SetTax` | Thiếu tiền (tăng), hạnh phúc sắp thấp (giảm) |
| | Mở giao thương/cảng | `StartTrade`, `PlaceBuilding` | Dư tài nguyên, tính cách Merchant |
| PopulationManager | Xây công viên/đền | `PlaceBuilding` | Hạnh phúc thấp |
| | Mở khu việc làm | `SetZone` | Thất nghiệp cao |
| | Xây bệnh viện | `PlaceBuilding` | Dịch bệnh, tỷ lệ chết cao |
| MilitaryAdvisor | Xây trại lính/tháp canh/tường | `PlaceBuilding` | Đe dọa gần biên giới, quan hệ xấu |
| | Tuyển lính | `RaiseArmy` | Chuẩn bị/đang chiến tranh |
| | Hành quân, bao vây, rút lui | `MoveArmy` | Chiến dịch đang diễn ra |
| DiplomacyAdvisor | Tặng quà | `SendGift` | Muốn cải thiện quan hệ |
| | Liên minh | `ProposeAlliance` | Quan hệ > 60, có kẻ thù chung |
| | Tuyên chiến | `DeclareWar` | Xem mục 6.4 |
| | Đình chiến | `ProposePeace` | Mệt mỏi chiến tranh, thua, kiệt quệ |

## 6. Logic chi tiết

### 6.1 CityPlanner
- **Chấm điểm vị trí thành phố:** `+ gần nước, + màu mỡ, + gần tài nguyên, + địa hình xây được, - gần biên giới địch, - gần quái vật, - quá gần thành khác (tối thiểu N ô)`.
- **Đường:** A* từ trung tâm đến cụm cần nối; ưu tiên tái sử dụng đường sẵn có; tránh cắt rừng/đất màu mỡ khi có lựa chọn khác.
- **Zone:** R gần dịch vụ và xa công nghiệp; I ở rìa/gần mỏ/nông nghiệp, tách khỏi R; C ở trục đường chính.
- **Hạ tầng:** chọn điểm phủ được nhiều ô thiếu nhất trong bán kính; không xây nhà máy ô nhiễm gần khu R.
- **Dịch vụ:** cứ `N` dân cần 1 công trình (số N trong `ai.json`), đặt tại điểm tối đa dân được phủ.
- **Mở rộng:** khi chỗ còn lại thấp hoặc tài nguyên cạn → `FoundCity` ở vị trí tốt mới và gửi một nhóm dân đi định cư.

### 6.2 EconomyManager
- Giữ **quỹ dự phòng ≥ chi 3 tháng**; dưới ngưỡng thì không xây công trình tốn tiền (trừ nông trại khi sắp đói).
- Dự báo thức ăn 3 tháng; thiếu → ưu tiên nông trại, giao thương, nếu Warlord thì cướp.
- Thuế điều chỉnh bước nhỏ (±2%/tháng), tránh dao động.
- Không xây nếu `balance` dự báo âm kéo dài.

### 6.3 PopulationManager
- Cân bằng: nhà ở ≈ dân, việc làm ≈ lao động. Lệch → hành động tương ứng.
- Hạnh phúc dưới ngưỡng → công viên, đền, giảm thuế, giảm ô nhiễm; dưới ngưỡng nổi loạn → ưu tiên cao nhất.
- Dịch bệnh → bệnh viện, tránh mở đường vào vùng nhiễm.

### 6.4 DiplomacyAdvisor và MilitaryAdvisor
- **Đánh giá láng giềng:** sức mạnh tương đối, quan hệ, lợi ích thương mại, khác chủng tộc/tôn giáo, biên giới chung.
- **Tuyên chiến khi** (tất cả): không đang có chiến tranh lớn, `war_cooldown` hết, sức mạnh ta ≥ `war_strength_ratio` × địch, **và** một trong: tính cách Warlord/Zealot, thiếu tài nguyên mà địch có, quan hệ < -60.
- **Chiến dịch:** chọn mục tiêu thành yếu nhất/giàu nhất gần nhất, tập kết, hành quân, bao vây; **rút** nếu thương vong vượt ngưỡng.
- **Xin hòa khi:** thua nặng, kiệt quệ kinh tế, hạnh phúc sắp nổi loạn, hoặc mệt mỏi chiến tranh cao.
- **Liên minh:** gửi đề nghị khi có kẻ thù chung, bên kia chấp nhận tùy quan hệ và tính cách. Đồng minh có thể **phản bội** (xác suất thấp, tăng khi đồng minh yếu đi).

### 6.5 Chống "xây rồi phá" (thrashing)
- Memory ghi vị trí vừa phá/xây trong N tháng; không đặt công trình ngược lại tại đó.
- Phạt điểm hành động giống hệt vừa bị `validate` từ chối.
- Hành động có **trễ** (cooldown) theo loại (vd: không đổi thuế 2 tháng liên tiếp).
- Chỉ số theo dõi: tỷ lệ lệnh bị từ chối, tỷ lệ công trình bị phá trong 12 tháng đầu.

## 7. Chronicle (nhật ký lịch sử)

Mỗi sự kiện đáng kể ghi một mục:
```json
{
  "year": 42, "month": 7, "type": "war_declared",
  "actors": [3, 5], "location": [64, 40],
  "text_key": "CHRON_WAR_DECLARED", "args": {"a": "Ardan", "b": "Gorak"},
  "importance": 4, "by_god": false
}
```

**Loại sự kiện và `importance` (1-5):**

| Mức | Ví dụ |
|---|---|
| 1 | Sinh con, xây công trình thường |
| 2 | Làng thành thành phố, mùa bội thu, thương đoàn |
| 3 | Thành phố mới, liên minh, dịch nhỏ, anh hùng ra đời |
| 4 | Tuyên chiến, mất/chiếm thành, đại dịch, ly khai, thiên tai lớn |
| 5 | Vương quốc thành lập/diệt vong, vua chết, nội chiến, thảm họa diện rộng, quyền thần lớn |

`importance` quyết định: có hiện toast không, Auto-Camera có bay tới không (≥ 4 mặc định), có lọt vào "Tóm tắt thế kỷ" không.

## 8. Drama Director (giữ thế giới thú vị, không làm giả)

- Mỗi năm, tính **chỉ số yên ắng**: số sự kiện `importance ≥ 3` trong 10 năm gần nhất. Quá thấp → tăng nhẹ xác suất thiên tai, anh hùng, phản loạn, sự kiện lựa chọn.
- Một vương quốc chiếm quá nhiều lãnh thổ/dân → tăng xác suất ly khai, dịch, nội bộ lục đục ở đó.
- Thế giới sắp mất hết vương quốc → tăng xác suất di dân lập thôn mới, người sống sót lập vương quốc.
- Chỉ **tác động xác suất**, không sửa kết quả sau khi đã xảy ra. Tắt/mở trong `ai.json` (`drama_director.enabled`).

## 9. Chế độ quan sát

- **AutoCamera:** chấm điểm mục tiêu theo `importance`, độ mới, khoảng cách camera; cooldown giữa các lần bay; chuyển cảnh mượt; có thể khóa vào vương quốc/nhân vật.
- **Timeline:** lọc theo vương quốc/loại/độ quan trọng; bấm mục để camera tới vị trí.
- **Biểu đồ:** dân số, quân sự, kinh tế, lãnh thổ theo năm cho từng vương quốc.
- **Bản đồ chính trị:** màu vương quốc, đường quan hệ.
- **Hồ sơ:** vương quốc (lịch sử, tính cách, lãnh đạo, kẻ thù, đồng minh), nhân vật (gia phả, thành tựu).
- **Tóm tắt thế kỷ:** liệt kê top sự kiện, vương quốc nổi bật, kỷ nguyên.
- **AI Debug (bật được):** bấm vương quốc xem điểm các hành động ứng viên, hành động đã chọn, lý do, lệnh bị từ chối.

## 10. Kiểm thử và cân bằng

Chạy `tools/sim_runner.gd` (xem Tech Spec mục 11.1). Báo cáo mỗi lần chạy:
```
seed, years, final_kingdoms, peak_population, min_population,
wars_count, longest_peace_years, collapses[],
commands_total, commands_rejected_pct, thrash_pct,
avg_ms_per_system{}, errors[]
```

**Cách chỉnh khi lệch:**

| Triệu chứng | Nguyên nhân hay gặp | Chỉnh |
|---|---|---|
| Cả thế giới chết đói | Nông trại ít/điểm thấp, tiêu thụ cao | Tăng trọng số food, giảm `food_per_month`, tăng `farm_output` |
| Một vương quốc nuốt hết | War ratio thấp, không có mệt mỏi chiến tranh | Tăng `war_cooldown`, chi phí quân đội, ly khai |
| Không có chiến tranh | Ngưỡng tuyên chiến quá khắt | Giảm ngưỡng, tăng trọng số Warlord |
| Chiến tranh liên miên | Không có xin hòa | Tăng mệt mỏi, hạnh phúc ảnh hưởng chiến tranh |
| AI xây rồi phá | Thiếu Memory/cooldown | Tăng thời gian nhớ, cooldown |
| Dân bùng nổ rồi sụp | Sinh quá nhanh, hạ tầng đuổi không kịp | Giảm birth rate, tăng giới hạn nhà ở |
| Không có gì xảy ra | Thiên tai/sự kiện thấp | Tăng tần suất, bật Drama Director |

Sửa `data/` trước, sửa code sau.

## 11. Luật bổ sung cho agent (nằm trong AGENTS.md)

- AI trong `src/sim/ai/`, không phụ thuộc Node. AI chỉ đọc state và phát Command.
- Người chơi và AI dùng chung Command. UI/Tool không sửa state trực tiếp.
- AI không gian lận.
- Hằng số AI trong `data/ai.json`. RNG có seed.
- Mỗi milestone AI kèm báo cáo sim_runner (dân số, số vương quốc, thrashing, lệnh bị từ chối).
