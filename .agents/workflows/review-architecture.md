# /review-architecture: rà soát kiến trúc

Chạy sau mỗi 2-3 milestone. KHÔNG sửa code, chỉ báo cáo.

Kiểm tra và liệt kê vi phạm kèm file/dòng:
1. File trong `src/sim/` có dùng Node/SceneTree/`get_tree()` không.
2. Có Node nào tạo cho từng cư dân không.
3. Có số cân bằng hard-code trong `.gd` thay vì `data/*.json` không.
4. Có API Godot 3 không. Có biến/hàm thiếu kiểu không.
5. Hệ thống nào gọi chéo trực tiếp thay vì `EventBus`.
6. File nào > 400 dòng. Vòng lặp nào có nguy cơ chậm (O(n^2) trên cư dân/ô).
7. RNG nào không có seed.

Kết thúc bằng danh sách ưu tiên sửa (cao/vừa/thấp) và đề xuất milestone refactor nếu cần.
