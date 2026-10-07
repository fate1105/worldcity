# /perf-check: kiểm tra hiệu năng

1. Dùng debug overlay (FPS, số cư dân, ms mỗi hệ thống). Nếu chưa có, thêm bằng `Time.get_ticks_usec()`.
2. Chạy mô phỏng headless 50 năm game với 1000 cư dân, ghi ms trung bình mỗi tick cho từng hệ thống.
3. Chỉ ra 3 hệ thống chậm nhất và nguyên nhân khả dĩ.
4. Đề xuất tối ưu (time-slicing, cache đường đi, dirty flag, giảm vẽ). Chờ tôi duyệt rồi mới sửa.
