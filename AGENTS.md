# WorldCity

Game 2D top-down: xây thành phố (kiểu TheoTown) trong thế giới sống (kiểu WorldBox).
Engine: **Godot 4.x**, ngôn ngữ **GDScript có kiểu**. Mục tiêu: chạy mượt trên điện thoại.

## Đọc trước khi làm
- `docs/GDD_WorldCity.md`: gameplay, cơ chế (nguồn sự thật về gameplay)
- `docs/WorldCity_Godot_Tech_Spec.md`: kiến trúc, thư mục, milestone (nguồn sự thật về công nghệ)
- Luật chi tiết nằm trong `.agents/rules/`. Quy trình trong `.agents/workflows/`.

## Luật cốt lõi (không được vi phạm)
1. Logic mô phỏng ở `src/sim/`, KHÔNG phụ thuộc Node/SceneTree. Hiển thị ở `src/view/`, `src/ui/`.
2. KHÔNG tạo 1 Node cho mỗi cư dân. Dùng `CitizenStore` (PackedArray) + MultiMesh.
3. Số liệu cân bằng nằm trong `data/*.json`, không hard-code.
4. Hệ thống giao tiếp qua signal của autoload `EventBus`.
5. Chỉ dùng API Godot 4 (CharacterBody2D, @onready, TileMapLayer, AStarGrid2D). Cấm API Godot 3.
6. GDScript phải có kiểu ở mọi biến và hàm.
7. RNG có seed, seed lưu trong WorldState.
8. Chỉ làm đúng milestone được yêu cầu. Không tự thêm tính năng. Giữ nguyên tính năng cũ.

## Kiểm tra sau mỗi thay đổi
Chạy `godot --headless --path . --quit-after 120` và báo lỗi nếu có.
Nếu không chạy được lệnh, nói rõ và hướng dẫn tôi chạy tay.

## Trả lời bằng tiếng Việt. Code, tên biến, comment code bằng tiếng Anh.
