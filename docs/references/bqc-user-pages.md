# Đối chiếu ảnh sách do người dùng cung cấp

Nguồn: ảnh bảng tọa độ trang 152–153, sơ đồ chính diện/trắc diện trang 154–155 và phần giải thích “Định vị các huyệt BQC”. Sơ đồ ghi © Bùi Quốc Châu 1983; chưa xác định năm xuất bản của bản sách được chụp.

Đã chép 251 mã từ hai trang bảng vào `mobile/lib/bqc_grid_reference.dart`, cộng 4 mã thấy trên sơ đồ nhưng không thấy hàng tương ứng trong bảng (243, 281, 283, 329). Danh mục tra cứu sinh trực tiếp từ dữ liệu này để không bỏ sót mã đã nhập. Đây là bản chép ảnh cần kiểm duyệt, không phải xác nhận đã số hóa đầy đủ mọi chấm của sách. Hàng của mã 48 không rõ trong ảnh nên để chưa rõ; giữ các mục còn nghi vấn kèm ghi chú.

- Chữ là cột, số là hàng. Khoảng C–D / 4–5 là một ô chứa huyệt, không xác định chấm chính xác ở tâm ô.
- Giữ nguyên ô nguồn; tâm ô chỉ dùng để minh họa. Lưới pixel trên hình của ứng dụng được căn thủ công, chưa đo chuẩn từ ảnh sách bị cong và nghiêng.
- Các huyệt hai bên được tạo hai vị trí đối xứng. Trái/phải trong dữ liệu là phía người xem sơ đồ, không tự suy diễn ý nghĩa ký hiệu +/−.
- Huyệt sau tai, cột ngoài mặt trước, vùng dưới mũi và mã chưa đối chiếu không được đặt điểm phỏng đoán lên mặt trước.
- Huyệt 62: bảng trang 152 đọc được hàng 9, sơ đồ trắc diện đặt gần hàng 11. Giữ giá trị bảng và đánh dấu cần đối chiếu, chưa ánh xạ. Các mã 39, 85 có khác biệt giữa bảng và hình mặt trước cũng chưa được ánh xạ.
- Một số huyệt đường giữa dùng hiệu chỉnh hình 2D hiện có; tất cả vị trí vẫn là minh họa, chưa được chuyên gia xác nhận.

Mặt 3D dùng cùng tọa độ chuẩn hóa với 2D rồi neo vào tam giác bề mặt. Điều này giữ điểm đi cùng mô hình khi xoay, nhưng không tự chứng minh độ chính xác giải phẫu. Bước tiếp theo là số hóa chấm trong từng ô sau khi hiệu chỉnh biến dạng ảnh, đối chiếu hai góc nhìn và kiểm duyệt từng mã.

## Cập nhật từ file ảnh gốc người dùng cung cấp

Hai ảnh nguyên bản được lưu tại `source-images/` và đóng gói trong `mobile/assets/references/` để đối chiếu trong ứng dụng. Nguồn đọc thủ công: `bqc-front-dots.csv` (198 mã) và `bqc-side-dots.csv` (không gồm sơ đồ sau tai). Tọa độ CSV tính theo khung ảnh hiển thị 1368 × 1824; tỉ lệ ảnh gốc 1920 × 2560 không đổi.

`tools/build_bqc_digitized.py` căn từng dải hàng/cột từ ảnh chính diện sang hình minh họa của ứng dụng. Điểm nằm giữa các đường lưới giữ vị trí nội suy từ chấm quan sát, không lấy tâm ô. Cách này bù độ nghiêng/convergence cục bộ, **không phải phục hồi đầy đủ độ cong trang sách**. Điểm hai bên lấy một phía được đọc và đối xứng trên hình đích; sai số đọc thủ công và khác biệt tỉ lệ hình minh họa vẫn còn.

`bqcFrontPositions` hiện chỉ dùng chấm đã đọc, không dùng tâm ô hoặc các hiệu chỉnh đường giữa cũ. Các mã 270, 399, 428 trên hình chính diện và 265 trên hình trắc diện được bổ sung. Tổng danh mục hiện 259 mã; đây không phải số điểm đã ánh xạ 3D. Mã 277 trước đây bị đọc nhầm từ hàng 287 lặp trong bảng; mã 277 có trên hình trắc diện nên giữ trong danh mục nhưng không dùng tọa độ B/8–9 để dựng mặt trước.

Xem `bqc-front-review.html` để đối chiếu vòng đỏ với chấm trên ảnh gốc. Trong ứng dụng, chọn huyệt rồi bấm “Đối chiếu chấm trên tài liệu”; hình có thể phóng to. Những mã chỉ có ở hình trắc diện được lưu trong hệ tọa độ ảnh nguồn, được chiếu ước lượng lên bề mặt 3D theo mô tả bên dưới. Mã chỉ có bảng nhưng chưa xác định được chấm (ví dụ 46, 437) không vẽ tọa độ phỏng đoán. Kiểm thử xác nhận tính nhất quán dữ liệu và phép neo tam giác, không thay thế kiểm duyệt vị trí huyệt.


### Ánh xạ trắc diện 3D
Điểm chưa có vị trí chính diện được chiếu từ ảnh tr.155 sang mặt phẳng độ sâu/chiều cao của mô hình canonical, chọn tam giác ngoài cùng trên mỗi nửa mặt và giữ tọa độ barycentric khi xoay. Đăng ký ảnh dùng các mốc chiều cao và tỷ lệ ngang 48 pixel/đơn vị mô hình: đây là ước lượng đồ họa, chưa phải hiệu chuẩn chuyên môn. Điểm ngoài bề mặt không được kéo về tam giác gần nhất; các huyệt sau tai vẫn bị loại khỏi danh mục hiển thị. Điểm chính diện có sẵn được ưu tiên. Màu điểm đỏ/xanh xen kẽ. Bộ lọc đường viền ảnh 2D ẩn các điểm trên phần nền trắng ngoài mặt.
