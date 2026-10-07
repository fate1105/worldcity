# Kỷ luật làm việc

1. Mỗi lần chỉ làm MỘT milestone (xem Tech Spec mục 13). Không làm trước phần sau.
2. Trước khi code: nêu kế hoạch ngắn (file sẽ tạo/sửa). Sau khi code: chạy kiểm tra headless.
3. Không xóa hoặc viết lại tính năng cũ nếu không được yêu cầu. Nếu cần refactor, nói trước lý do.
4. Có logic mô phỏng mới thì thêm test GUT trong `tests/` (nếu GUT đã cài).
5. Thêm số liệu mới vào `data/*.json`, không hard-code trong `.gd`.
6. Mâu thuẫn giữa GDD và Tech Spec: gameplay theo GDD, công nghệ theo Tech Spec. Còn mơ hồ thì hỏi tôi, đừng đoán.
7. Kết thúc mỗi milestone báo cáo: đã làm gì, file nào đổi, cách chạy thử, việc tôi phải làm tay, rủi ro/nợ kỹ thuật.
8. Không cài thêm addon/thư viện ngoài khi chưa hỏi.
9. File dài quá 400 dòng thì đề xuất tách.
