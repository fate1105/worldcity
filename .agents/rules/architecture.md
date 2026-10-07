# Kiến trúc WorldCity

- **Sim tách khỏi View.** `src/sim/` là logic thuần (`RefCounted`/dữ liệu), `src/view/` + `src/ui/` chỉ vẽ và nhận input, chỉ ĐỌC state.
- **Autoload:** `EventBus`, `GameClock`, `DataDB`, `SaveSystem`, `Settings`.
- **Dữ liệu lưới:** mỗi layer một PackedArray `W*H`, truy cập `idx = y*W + x`.
- **Cư dân:** `CitizenStore` dạng SoA (nhiều PackedArray). id = chỉ số mảng, dùng free-list tái sử dụng slot. Vẽ bằng MultiMesh.
- **Tick cố định 10/giây ở x1.** Giới hạn số tick tối đa mỗi frame. Phân tầng: mỗi tick / ngày (100 tick) / tháng / năm.
- **Time-slicing:** cư dân chia 10 nhóm, tick n chỉ xử lý nhóm `n % 10`. Có ngân sách thời gian mỗi frame.
- **Tìm đường:** `AStarGrid2D` + hàng đợi yêu cầu, tối đa K yêu cầu/tick.
- **Data-driven:** `DataDB` nạp `data/*.json`, kiểm tra schema, báo lỗi rõ khi thiếu trường.
- **Lưu/tải:** `WorldState.to_dict()` / `from_dict()`, có `save_version` và hàm migrate.
- **Chunk:** TileMapLayer chia chunk 32x32, chỉ cập nhật chunk bẩn (dirty), chỉ hiện chunk trong camera.
- **Hiệu năng mục tiêu:** 60 FPS với 1000 cư dân, bản đồ 128x128, điện thoại tầm trung.
- Hệ thống không gọi chéo trực tiếp nhau. Dùng `EventBus`.
