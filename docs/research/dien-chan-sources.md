# Đối chiếu nguồn huyệt Diện Chẩn

Ngày đọc: 2026-10-11. Chưa có bộ tọa độ 3D đã kiểm chứng.

## Nguồn đã đọc

- Académie Dien Chan, Lexique et vocabulaire: https://academiedienchan.com/lexique.php
  Mô tả hệ đường tham chiếu theo mốc giải phẫu, không phải lưới chia đều theo pixel.
  Các ví dụ: 63 giữa rãnh nhân trung, đường ngang 9; 127 giữa nếp lõm cằm, đường 11 phía trên; 87 nằm trên đường 12 chia đôi phần nổi cằm.
- École Internationale de Multiréflexologie: https://www.dienchan.org/point-bqc-dienchan.php
  Hướng dẫn tiếp cận/định vị điểm BQC trong thực hành. Không cung cấp bộ tọa độ 3D để nhập trực tiếp.
- Diện Chẩn Bùi Quốc Châu, Các cột mốc lịch sử:
  https://dienchan.com/nhung-cot-moc-lich-su-cua-phuong-phap-dien-chan-dieu-khien-lieu-phap-bui-quoc-chau
  Dùng xác định xuất xứ hệ thống; không dùng làm nguồn tọa độ từng huyệt.

## Sai khác trong dữ liệu app

- 127 đang được mô tả gò má trong phải, khác định vị nếp lõm cằm ở nguồn Académie.
- 87 đang được mô tả gần quai hàm phải, khác định vị đường giữa vùng cằm ở nguồn Académie.
- Lưới 2D chia đều khung hiển thị và tọa độ chuẩn hóa hardcode chưa tái hiện hệ mốc giải phẫu của tài liệu.
- Bản đồ 3D nội suy từ dữ liệu này nên kế thừa sai lệch. Không sửa tọa độ bằng cách đoán từ một mô tả văn bản.

## Đã bổ sung

Màn Tra huyệt có mục nguồn đối chiếu; kết quả 63/127/87 hiển thị mô tả tham chiếu với tên nguồn. Tất cả vị trí hiển thị vẫn ghi chưa xác minh. Chưa di chuyển điểm hoặc đánh dấu đã duyệt.

## Dữ liệu cần để chuẩn hóa toàn bộ

Chọn một ấn bản đồ hình chính diện/nghiêng có tác giả, phiên bản, trang và quyền sử dụng rõ ràng. Đối chiếu từng mã và bên mặt; lưu mô tả định vị, đường tham chiếu, trang nguồn, tọa độ đã hiệu chỉnh và người duyệt. Sau khi duyệt 2D mới hiệu chỉnh neo 3D. Các nguồn đào tạo mô tả hệ Diện Chẩn không tương đương bằng chứng lâm sàng cho các tuyên bố điều trị.
