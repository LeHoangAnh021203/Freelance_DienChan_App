# Dien Chan App

Monorepo cho ứng dụng Diện Chẩn, tách phần client, backend, tài liệu và hạ tầng theo cấu trúc giống `Exotic Stamp`.

## Tech Stack

- Mobile/client chính: Flutter trong `mobile/`
- Legacy web prototype: `mobile/legacy-web/`
- Backend: Node.js API không cần dependency ngoài
- Data: JSON database local trong `backend/data/store.json`
- Deploy/local tooling: script trong `infra/`

## Repository Structure

- `mobile/`: ứng dụng người dùng cuối
- `backend/`: API và business services trong giai đoạn thiết kế
- `docs/`: kiến trúc, API, database và business rules
- `infra/`: cấu hình môi trường, Docker notes và script chạy local

## Current Status

- Đã bootstrap Flutter app thật trong `mobile/`
- Đã giữ bản web cũ tại `mobile/legacy-web/`
- Flutter UI đang theo style `Exotic Stamp`: theme xanh/đỏ, bottom nav, nút scan nổi giữa, card trắng
- Có luồng chụp mặt bằng camera native qua `image_picker` và phủ điểm huyệt lên ảnh đã chụp
- Đã có backend API cho catalog, settings và journals
- Đã nhập các nhóm dữ liệu từ `Dien_Chan_Data_PRD.docx`: đồ hình, điểm chạm, nguyên lý, dụng cụ, product spec, bookmark và hồ sơ theo dõi
- Đã tạo khung tài liệu sản phẩm và kỹ thuật
- Đã tách dữ liệu runtime sang `backend/data/store.json`
- Chưa có đăng nhập thật và database production

## How To Use Source

### Mobile

- Entry point Flutter: `mobile/lib/main.dart`
- Android/iOS/Web platform files: `mobile/android`, `mobile/ios`, `mobile/web`
- Legacy web prototype: `mobile/legacy-web/`

### Backend

- Entry point: `backend/server.js`
- Local database: `backend/data/store.json`
- API contract: `docs/api/`

## Run Local

### Chuẩn bị môi trường

Cần Flutter SDK, Google Chrome (chạy web) và Node.js/npm (chạy backend).
Dự án hỗ trợ Dart **3.11.1 trở lên**. Dependency nhận diện khuôn mặt được ghim
ở `google_mlkit_face_detection: 0.14.0`, camera dùng `^0.12.0+2` để tương thích
với SDK hiện tại. Không cần nâng Flutter để chạy với Dart 3.11.1.

Kiểm tra SDK bằng `flutter --version`, sau đó chạy các lệnh bên dưới.

### Chạy giao diện trên Chrome

Từ thư mục gốc dự án, mở terminal thứ nhất:

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port 8080
```

Giao diện mở tại http://localhost:8080. Giữ terminal chạy trong khi sử dụng app.
Nhấn `r` để hot reload, `R` để hot restart, hoặc `q` để dừng Flutter.

### Backend/API local

Mở terminal thứ hai tại thư mục gốc dự án (thư mục chứa `package.json`):

```bash
npm run dev
```

Backend không cần cài dependency ngoài. Kiểm tra API tại:

```text
http://127.0.0.1:5173/api/v1/health
```

Nhấn `Ctrl+C` để dừng backend.

### Chạy trên điện thoại hoặc máy ảo

Kết nối thiết bị hoặc mở máy ảo, sau đó chạy từ thư mục gốc dự án:

```bash
cd mobile
flutter pub get
flutter devices
flutter run -d <device-id>
```

Thay `<device-id>` bằng mã thiết bị từ `flutter devices`.

### Legacy web prototype

Chạy từ thư mục gốc dự án. Dừng backend trước vì cùng dùng cổng 5173.

```bash
cd mobile/legacy-web
python3 -m http.server 5173
```

## Suggested Next Steps

1. Tách dữ liệu mẫu trong `mobile/web/app.js` sang JSON hoặc API.
2. Chọn backend framework và bootstrap trong `backend/`.
3. Chuẩn hóa database schema cho huyệt, bệnh, triệu chứng, phác đồ và nhật ký.
4. Kết nối client với API thật.

## Chức năng Hồ sơ

- Khách chỉ thấy ảnh đại diện, tên Khách và nút đăng ký/đăng nhập.
- Chỉnh sửa hồ sơ: cập nhật họ tên, điện thoại, Gmail, quốc gia; kiểm tra dữ liệu và lưu trên thiết bị.
- Bảo mật và riêng tư: xóa ảnh khuôn mặt hoặc xác nhận xóa hồ sơ, lịch nhắc và bản nháp hỗ trợ trên thiết bị.
- Thông báo: bật/tắt lịch nhắc hằng ngày, chọn giờ và thử thông báo. Lịch được lưu; nhắc chỉ hoạt động khi app đang mở và đã đăng nhập, theo giờ thiết bị, tối đa một lần mỗi ngày.
- Trợ giúp: câu hỏi thường gặp, lưu bản nháp hỗ trợ và sao chép nội dung. Chưa cấu hình kênh gửi hỗ trợ.
- Đăng xuất: xóa hồ sơ và ảnh trong phiên, chuyển về khách. Cài đặt nhắc giờ và bản nháp vẫn thuộc thiết bị; dùng Xóa dữ liệu cá nhân để xóa tất cả các mục này.
- Thống kê hiển thị chưa có dữ liệu thay vì số mẫu.

Hồ sơ hiện lưu cục bộ, chưa có xác thực máy chủ, mật khẩu/OTP/sinh trắc học,
thông báo nền hoặc đồng bộ tài khoản giữa các thiết bị.

## Đồ hình 3D tham khảo

Mở **Tra huyệt** để xem trực tiếp mặt 3D phủ nét vẽ từ ảnh 2D.
Kéo để xoay, chụm để thu phóng, chạm hai lần để đặt lại góc nhìn.
Điểm huyệt hiển thị đỏ/xanh xen kẽ và neo vào tam giác để đi cùng mặt khi xoay.
Bộ lọc đường viền ẩn điểm ở phần nền trắng ngoài hình mặt.
Các nút phụ, thông tin kỹ thuật và nút chuyển 2D đã được bỏ khỏi màn hình chính.

Dữ liệu tham chiếu gồm 259 mã, 198 mã được số hóa từ sơ đồ chính diện
và 98 mã từ sơ đồ trắc diện (có mã trùng giữa hai sơ đồ).
Các điểm trắc diện được chiếu ước lượng khi nằm trong lưới; tạm bỏ huyệt sau tai.
Không phải tất cả mã đều có điểm hiển thị. Tọa độ chưa được kiểm duyệt chuyên môn.
Ảnh nguồn và ghi chú tại `docs/references/bqc-user-pages.md`.

Mô hình MediaPipe OBJ đóng gói sẵn, vẽ bằng Flutter Canvas, không cần CDN.
Nguồn, giấy phép và checksum tại `mobile/assets/models/README.md`.
