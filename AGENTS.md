# WorldCity

Game 2D top-down: xây thành phố (kiểu TheoTown) trong thế giới sống (kiểu WorldBox).
Engine: **Godot 4.x**, ngôn ngữ **GDScript có kiểu**. Mục tiêu: chạy mượt trên điện thoại.

## Đọc trước khi làm
- `docs/GDD_WorldCity.md`: gameplay, cơ chế (nguồn sự thật về gameplay)
- `docs/WorldCity_Godot_Tech_Spec.md`: kiến trúc, thư mục, milestone (nguồn sự thật về công nghệ)
- Luật chi tiết nằm trong `.agents/rules/`. Quy trình trong `.agents/workflows/`.

## Luật cốt lõi (không được vi phạm)
1. **Kiến trúc mô phỏng:** Logic ở `src/sim/`, KHÔNG phụ thuộc Node/SceneTree. Hiển thị ở `src/view/`, UI ở `src/ui/`.
2. **Quản lý dữ liệu lớn:** KHÔNG tạo 1 Node cho mỗi cư dân. Dùng `CitizenStore` (Struct of Arrays / PackedArray) + `MultiMesh` để vẽ.
3. **Định hướng Gameplay (Zero-player / God Game):** Trò chơi hoàn toàn tự động (Autonomous). AI Cư dân tự quyết định sinh hoạt qua Utility AI, tự xây nhà, mở rộng lãnh thổ và sinh sản. Không sử dụng hệ thống Quy hoạch vùng (Zones).
4. **Hệ thống Đặc tính:** Mọi hành vi phụ thuộc vào 8 Chỉ số RPG cá nhân, Đặc điểm (Traits), Giới tính và Thời gian thực (Ngày/Đêm).
5. **Cân bằng & Tương tác:** Số liệu cân bằng nằm trong `data/*.json`, không hard-code. Giao tiếp qua signal của autoload `EventBus`.
6. **Code Convention:** Chỉ dùng API Godot 4. GDScript bắt buộc phải có kiểu (Static Typing) ở mọi biến và hàm.
7. **Tính tất định:** RNG phải có seed, seed được lưu trong `WorldState`.
8. Chỉ làm đúng milestone được yêu cầu, nhưng được phép sáng tạo các tính năng AI để game sống động hơn.

## Kiểm tra sau mỗi thay đổi
Chạy `godot --headless --path . --quit-after 120` và báo lỗi nếu có.
Nếu không chạy được lệnh, nói rõ và hướng dẫn tôi chạy tay.

## Trả lời bằng tiếng Việt. Code, tên biến, comment code bằng tiếng Anh.
