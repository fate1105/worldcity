# WorldCity

**WorldCity** là một tựa game mô phỏng 2D top-down theo phong cách **Zero-player / God Game**. Lấy cảm hứng từ *WorldBox* và *Dwarf Fortress*, trong WorldCity, thế giới sống và tự vận hành hoàn toàn độc lập. Bạn sẽ đóng vai trò là một vị thần quan sát lịch sử phát triển của các vương quốc, từ những nhóm người tiền sử đầu tiên cho đến khi xây dựng thành một đế chế hùng mạnh.

## 🌟 Tính năng cốt lõi

- **Trò chơi tự vận hành (Autonomous):** AI Cư dân và Vương quốc tự quyết định mọi thứ. Họ tự sinh hoạt, tự đi khai hoang, dựng nhà cửa, phát triển kinh tế và ngoại giao mà không cần người chơi phải "quy hoạch" hay thao tác nhấp chuột mỏi tay.
- **Utility AI của Cư dân:** Mỗi NPC là một thực thể độc lập có gia phả, nhu cầu (Đói, Hạnh phúc, Tiền bạc) và thời gian biểu (Ngày/Đêm). Họ biết tự kiếm việc làm, lấy tiền mua đồ ăn, đi chơi xài tiền, rảnh rỗi thì tập thể dục tăng cường sức khỏe, ban đêm lầm đường lạc lối thì đi... ăn trộm, và thậm chí là biết tán tỉnh, kết hôn với nhau!
- **Hệ thống 8 Chỉ số RPG & Trait:** Mỗi nhân vật sở hữu 8 chỉ số riêng biệt (Sức mạnh, Nhanh nhẹn, Trí tuệ, Thể lực, Sức hút, Khéo léo, May mắn, Dũng cảm). Các chỉ số này quyết định Đặc điểm (Traits) của họ (như Chăm chỉ, Lười biếng, Hung hãn, Lãnh đạo). Chỉ số có thể được di truyền cho thế hệ sau.
- **Xây dựng Hữu cơ (Organic Building):** Không còn chia vùng Zone cứng nhắc. Khu dân cư và công trình mọc lên một cách tự nhiên dựa trên nhu cầu thực tế của vương quốc.
- **Tùy biến Thần Thánh:** Bạn có thể nhập vai "Thần" để can thiệp vào thế giới bất cứ lúc nào (ban mưa, sấm sét, quăng quái vật...) bằng hệ thống Mana.

## 🎮 Cách cài đặt và chơi

1. **Yêu cầu:** Tải và cài đặt **Godot 4.x** (phiên bản mới nhất).
2. Tải toàn bộ mã nguồn của kho lưu trữ (repository) này về máy.
3. Mở **Godot Engine**, chọn **Import**, chỉ đường dẫn tới file `project.godot` trong thư mục game.
4. Bấm **F5** (Run) để bắt đầu mô phỏng thế giới.

## 🛠 Dành cho Nhà phát triển

WorldCity được xây dựng với nguyên tắc kiến trúc tách biệt rõ ràng giữa **Mô phỏng (Simulation)** và **Hiển thị (View)**, cho phép game có thể chạy *Headless* (không cần render đồ họa) để kiểm thử dữ liệu qua hàng trăm năm lịch sử.

Các tài liệu quan trọng nằm trong thư mục `docs/`:
- `GDD_WorldCity.md`: Thiết kế Gameplay chi tiết.
- `WorldCity_Godot_Tech_Spec.md`: Tài liệu kiến trúc Godot, hệ thống Command và quản lý dữ liệu lớn (Struct of Arrays / PackedArray).
- `AUTONOMOUS_MODE.md`: Chi tiết về cách tổ chức Utility AI và tư duy của Vương quốc.
- Thư mục `data/`: Chứa các file JSON dùng để cân bằng game mà không cần đụng vào code.

> **WorldCity - Nơi bạn ngắm nhìn những vương quốc trỗi dậy và suy tàn.**
