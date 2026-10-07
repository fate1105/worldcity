# /fix-bug: sửa lỗi

Dùng: `/fix-bug <mô tả hoặc dán log lỗi>`.

1. Đọc log, xác định file và dòng. Tái hiện lỗi bằng `godot --headless` nếu được.
2. Nêu nguyên nhân gốc (không chỉ triệu chứng) trước khi sửa.
3. Sửa tối thiểu. Không refactor ngoài phạm vi.
4. Chạy lại kiểm tra. Nếu là lỗi logic sim, thêm test hồi quy trong `tests/`.
5. Báo: nguyên nhân, file đã sửa, cách xác nhận đã hết lỗi.
