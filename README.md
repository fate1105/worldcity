# WorldCity: hướng dẫn bắt đầu

## 1. Cài đặt (làm 1 lần)
1. **Godot 4.x** (bản stable mới nhất): https://godotengine.org/download
2. **Git**: https://git-scm.com/downloads
3. **Thêm Godot vào PATH** để agent tự chạy `godot --headless`. Windows: đổi tên file Godot thành `godot.exe`, đặt vào thư mục cố định, thêm thư mục đó vào biến môi trường PATH. Kiểm tra: mở terminal gõ `godot --version`.
4. **Antigravity** (IDE bạn đang dùng).

## 2. Mở dự án
1. Giải nén thư mục `worldcity`.
2. Mở terminal trong thư mục đó: `git init` rồi `git add . && git commit -m "scaffold"`.
3. Mở thư mục này bằng Antigravity (File > Open Folder). Nó tự đọc `AGENTS.md` và `.agents/`.

## 3. Bắt đầu làm game
Trong khung chat agent của Antigravity gõ:

    /milestone 0

Xong thì tự mở Godot (Import project, chọn file `project.godot` mà agent tạo), bấm F5 chạy thử.
Nếu ổn: `git commit`, rồi `/milestone 1`, và cứ thế đến 14.

## 4. Lệnh có sẵn
| Lệnh | Việc |
|---|---|
| `/milestone N` | Làm milestone N theo Tech Spec |
| `/fix-bug <log>` | Sửa lỗi, tìm nguyên nhân gốc |
| `/review-architecture` | Rà soát kiến trúc sau mỗi 2-3 milestone |
| `/perf-check` | Đo và tối ưu hiệu năng |

Nếu `/lệnh` không hiện ra, bạn gõ nội dung tương ứng bằng lời, ví dụ: "Làm theo quy trình trong .agents/workflows/milestone.md cho milestone 1".

## 5. Cấu trúc
- `AGENTS.md`: luật cốt lõi, agent luôn đọc
- `.agents/rules/`: luật chi tiết (Godot 4, kiến trúc, kỷ luật)
- `.agents/workflows/`: quy trình
- `docs/`: GDD (gameplay) và Tech Spec (kiến trúc, 15 milestone)
- `data/`: số liệu cân bằng (JSON), chỉnh ở đây để cân bằng game
- `src/`, `tests/`, `assets/`: agent sẽ tạo nội dung

## 6. Các tính năng nổi bật đã hoàn thành
- **Utility AI siêu cấp:** Cư dân NPC có hệ thống sinh hoạt chi tiết dựa trên mức độ ưu tiên (Làm việc, Đi chơi, Ngủ, Phạm tội, Luyện tập, Kiếm ăn).
- **Hệ thống Chỉ số & Traits (Đặc điểm):** 8 chỉ số RPG (Sức mạnh, Nhanh nhẹn, Trí tuệ, Sức hút, May mắn, v.v...) và hàng loạt Đặc điểm cá nhân tính toán dựa trên chỉ số.
- **Tiền bạc & Hôn nhân:** Cư dân tự kiếm tiền từ việc đi làm, có thể dùng tiền mua đồ ăn hoặc giải trí. Cư dân gặp gỡ nhau có thể cầu hôn và dọn về ở chung nhà.
- **Chu kỳ Ngày/Đêm:** Hệ thống thời gian thực thay đổi sắc độ ánh sáng từ Bình minh, Buổi trưa, Hoàng hôn, cho đến Đêm khuya kết hợp đồng bộ với AI (Ví dụ: ban đêm đổ xô đi ngủ).

## 7. Mẹo
- Mỗi lần chỉ 1 milestone, test và commit rồi mới sang tiếp.
- Lỗi thì dán nguyên log cho agent kèm `/fix-bug`.
- Agent hay viết nhầm API Godot 3. Nếu gặp, nhắc "Godot 4.x, xem .agents/rules/godot4.md".
- Đừng cho nhiều agent chạy song song sửa cùng file.
