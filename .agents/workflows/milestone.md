# /milestone: làm một milestone

Dùng: `/milestone <số>` (ví dụ `/milestone 3`).

1. Đọc `AGENTS.md`, `.agents/rules/`, mục 13 của `docs/WorldCity_Godot_Tech_Spec.md` để lấy milestone được yêu cầu, phần liên quan trong `docs/GDD_WorldCity.md` và `docs/AUTONOMOUS_MODE.md` (nếu milestone liên quan AI/quan sát).
2. Kiểm tra milestone trước đã hoàn tất chưa (project chạy được, không lỗi). Nếu chưa, báo tôi và dừng.
3. Viết kế hoạch ngắn: danh sách file tạo/sửa, dữ liệu JSON cần thêm, rủi ro. Chờ tôi đồng ý nếu thay đổi lớn.
4. Code đúng phạm vi milestone, theo luật trong `.agents/rules/`.
5. Chạy `godot --headless --path . --quit-after 120`. Sửa lỗi cho tới khi sạch.
6. Nếu có logic sim mới: thêm test GUT và chạy.
7. Báo cáo theo mẫu ở `discipline.md` mục 7, kèm hướng dẫn tôi chạy thử bằng tay (nhấn gì, thấy gì thì đúng).
8. Đề xuất nội dung commit Git. DỪNG, không tự làm milestone tiếp theo.
