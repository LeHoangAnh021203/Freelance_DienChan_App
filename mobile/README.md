# Mobile App

Flutter app demo cho sản phẩm Sổ tay điện tử Diện Chẩn.

## Demo Nhanh Với Khách Hàng

App hiện có 3 concept giao diện để demo trực tiếp:

- `Mẫu A - FinFlow`: hiện đại, nổi khối, năng động.
- `Mẫu B - NestFind`: gọn, trẻ, ưu tiên khám phá nội dung.
- `Mẫu C - Night Care`: dark mode cao cấp, tập trung dùng buổi tối.

Mỗi concept đều giữ cùng logic chức năng theo tài liệu:

- Tra cứu: triệu chứng, bệnh, huyệt, đồ hình.
- Luồng chính: Triệu chứng -> Bệnh -> Phác đồ.
- Bệnh án/Nhật ký, Ghi chú & Lưu, Nhắc nhở giờ làm.
- Kết nối cộng đồng.
- Cá nhân/Cài đặt.

## Cập Nhật Mẫu C (Night Care)

Mẫu C đã được cập nhật nội dung và tài liệu để không chỉ là giao diện "dark", mà có thể demo tính năng thực tế như 2 mẫu còn lại:

- `Trang chủ`: có thống kê nhanh phác đồ/huyệt/nhắc giờ, phác đồ tối, cảnh báo an toàn, và block "Thông tin và tài liệu".
- `Tra cứu`: có ô tìm kiếm + nút giọng nói; danh sách gợi ý theo triệu chứng phổ biến.
- `Kết nối`: tách rõ thẻ `Bạn bè` và `Nhóm cộng đồng`; bấm vào sẽ mở trang danh sách chi tiết; nút `+` mở menu quét QR/kết nối nhanh.
- `Hồ sơ`: giữ luồng `QR của tôi` theo dạng bấm mới hiện (bottom sheet), kèm các mục bảo mật cơ bản.

Tài liệu mẫu đang hiển thị trong Mẫu C:

- `Tài liệu 64 huyệt diện chẩn` (mô tả vị trí, cách day ấn, lưu ý).
- `Quy trình tự chăm sóc 6 bước` (làm ấm, dò điểm, day ấn, theo dõi).

## Cách Chạy

Trong thư mục `mobile/`:

```bash
flutter pub get
flutter run
```

Hoặc chạy web để demo nhanh:

```bash
flutter run -d chrome
```

## Kịch Bản Show Cho Khách (7-10 phút)

1. **Mở màn Demo Picker (30s)**
   - Nói rõ: "Em chuẩn bị 3 hướng giao diện, chức năng giữ nguyên để mình chỉ tập trung chọn style".

2. **Show Concept A (2-3 phút)**
   - Nhấn mạnh cảm giác hiện đại/premium.
   - Chạy nhanh Home -> Tra cứu -> Luồng Triệu chứng -> Bệnh -> Phác đồ.

3. **Show Concept B (2-3 phút)**
   - Nhấn mạnh đọc nội dung y khoa dễ hơn, ít nhiễu.
   - Mở Kết nối + Cá nhân để khách thấy tính thực dụng.

4. **Show Concept C (2 phút)**
   - Nhấn mạnh tính ứng dụng buổi tối: dễ nhìn, tra cứu nhanh, tài liệu có sẵn để học/tự thực hành.

5. **Chốt lấy quyết định (1-2 phút)**
   - Hỏi 3 câu: 
     - "Anh/chị thích tổng thể concept nào nhất?"
     - "Màu sắc có cần điều chỉnh theo thương hiệu không?"
     - "Có màn nào cần ưu tiên chỉnh trước khi vào dev thật?"

## Gợi Ý Thu Feedback Đúng Trọng Tâm

- Chia feedback thành 3 nhóm: `Màu sắc`, `Bố cục`, `Mức độ dễ hiểu`.
- Tránh hỏi "thích không" chung chung; hỏi theo từng luồng cụ thể.
- Nếu khách chưa chốt được, đề xuất "chọn A làm base + lấy typography của B".
