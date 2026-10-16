# Dien Chan App

Monorepo cho ứng dụng Diện Chẩn, tách phần client, backend, tài liệu và hạ tầng theo cấu trúc giống `Exotic Stamp`.

## Tech Stack

- Mobile/client chính: Flutter trong `mobile/`
- Legacy web prototype: `mobile/legacy-web/`
- Backend: Node.js (>= 20) với `pg`, `ws`, `jose`; deploy trên Railway
- Data: PostgreSQL cho tài khoản, hồ sơ, chat, nhật ký, mục đã lưu, đăng ký khóa học; nội dung tra cứu vẫn đọc từ `backend/data/store.json`
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
- Đăng ký/đăng nhập thật bằng email + mật khẩu (quên mật khẩu qua email) và Apple
- Hồ sơ, ảnh đại diện, lịch nhắc, nhật ký, mục đã lưu, đăng ký khóa học lưu trên server theo tài khoản
- Chat cộng đồng và danh sách online realtime qua WebSocket, có báo cáo/chặn/xóa tin nhắn
- Thông báo trong app lấy từ server (chào mừng, xác nhận đăng ký khóa học, thông báo chung từ admin)
- Gửi yêu cầu hỗ trợ lên server; trang công khai `/privacy`, `/terms`, `/support`, `/delete-account` cho hồ sơ store
- Cảnh báo sức khỏe hiện ở lần mở app đầu tiên
- Bundle ID / Application ID: `com.dienchan.app`, tên hiển thị `DienChan`; iOS chỉ hỗ trợ iPhone, tối thiểu iOS 15.5

## How To Use Source

### Mobile

- Entry point Flutter: `mobile/lib/main.dart`
- Android/iOS/Web platform files: `mobile/android`, `mobile/ios`, `mobile/web`
- Legacy web prototype: `mobile/legacy-web/`

### Backend

- Entry point: `backend/server.js`; route API trong `backend/src/api.js`
- Schema Postgres tự tạo khi server khởi động (`backend/src/db.js`)
- Realtime chat/online: `backend/src/realtime.js` tại `/api/v1/realtime`
- Nội dung tra cứu: `backend/data/store.json`
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

Cần PostgreSQL chạy local (ví dụ `brew install postgresql@16 && brew services start postgresql@16`).
Mở terminal thứ hai tại thư mục gốc dự án (thư mục chứa `package.json`):

```bash
createdb dien_chan
npm install
npm run dev
```

`npm run dev` tự đọc file `.env` nếu có. Kiểm tra API tại:

```text
http://127.0.0.1:5173/api/v1/health
```

App Flutter mặc định gọi `http://localhost:5173` (máy ảo Android: `http://10.0.2.2:5173`).
Khi chạy local mà chưa có `RESEND_API_KEY`, mã quên mật khẩu được in ra terminal backend.
Chạy test backend (cần database `dien_chan_test`): `createdb dien_chan_test && npm test`.

Nhấn `Ctrl+C` để dừng backend.

### Biến môi trường backend

| Biến | Bắt buộc | Ý nghĩa |
| --- | --- | --- |
| `DATABASE_URL` | Có | Chuỗi kết nối Postgres (Railway: `${{Postgres.DATABASE_URL}}`) |
| `RESEND_API_KEY`, `MAIL_FROM` | Có khi production | Gửi mã quên mật khẩu qua [Resend](https://resend.com) |
| `ADMIN_EMAIL` | Nên có | Nhận email khi có đăng ký khóa học hoặc tin nhắn bị báo cáo |
| `ADMIN_TOKEN` | Nên có | Header `X-Admin-Token` cho `GET /api/v1/admin/course-registrations` và `POST /api/v1/admin/notifications` |
| `APPLE_CLIENT_IDS` | Khi dùng Apple | Bundle ID iOS (và Services ID nếu dùng Apple trên web), cách nhau dấu phẩy |
| `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | Tùy chọn | Thu hồi quyền Apple khi người dùng xóa tài khoản |
| `CORS_ORIGINS` | Tùy chọn | Domain web được gọi API, mặc định `*` |

### Deploy backend lên Railway

1. Tạo project trên Railway từ repo này, thêm dịch vụ **PostgreSQL**.
2. Ở service backend, đặt các biến môi trường ở bảng trên. `railway.json` đã cấu hình lệnh chạy `npm start` và healthcheck `/api/v1/health`.
3. Bật **Generate Domain** để có URL dạng `https://<app>.up.railway.app`.
4. Build app trỏ tới server thật, ví dụ:

```bash
cd mobile
flutter build web --release --dart-define=API_BASE_URL=https://<app>.up.railway.app
flutter build appbundle --dart-define=API_BASE_URL=https://<app>.up.railway.app
flutter build ipa --dart-define=API_BASE_URL=https://<app>.up.railway.app
```

Apple trên web cần thêm `--dart-define=APPLE_SERVICE_ID=...` và `--dart-define=APPLE_REDIRECT_URI=...`.

Gửi thông báo cho mọi người dùng (thêm `"userId"` để gửi riêng một người; `kind`: `info`, `course`, `warning`, `community`):

```bash
curl -X POST https://<app>.up.railway.app/api/v1/admin/notifications \
  -H "X-Admin-Token: $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Khai giảng khóa mới","body":"Đăng ký trong mục Khóa học.","kind":"course"}'
```

### Phát hành lên store

- Nội dung đăng store, khai báo quyền riêng tư và ghi chú cho người duyệt: `docs/store/store-listing.md`.
- Android ký bản release bằng `mobile/android/key.properties` + `mobile/android/app/upload-keystore.jks` (đã gitignore). **Sao lưu hai file này ở nơi an toàn**: mất chúng thì không cập nhật được app trên Google Play (trừ khi đã bật Play App Signing và xin reset upload key). Nếu thiếu `key.properties`, bản release tạm ký bằng debug key và Google Play sẽ từ chối.
- iOS: mở `mobile/ios/Runner.xcworkspace`, kiểm tra Team, bật capability **Sign in with Apple** cho App ID `com.dienchan.app`, rồi `flutter build ipa` và tải lên bằng Transporter hoặc Xcode.
- Đổi icon: thay `mobile/assets/branding/app_icon.png` (và `app_icon_foreground.png`), chạy `dart run flutter_launcher_icons` trong `mobile/`.

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

1. Chuẩn hóa database schema cho huyệt, bệnh, triệu chứng, phác đồ (hiện vẫn đọc từ `store.json`).
2. Thay dữ liệu chi tiết phác đồ mẫu bằng nội dung thật đã được chuyên môn duyệt.
3. Thông báo đẩy (push notification) cho lịch nhắc và thông báo từ admin.

## Chức năng Hồ sơ

- Khách chỉ thấy ảnh đại diện, tên Khách và nút đăng ký/đăng nhập.
- Đăng ký bằng họ tên, email, mật khẩu (tối thiểu 8 ký tự), điện thoại (không bắt buộc), quốc gia; hoặc Tiếp tục với Apple.
- Quên mật khẩu: nhận mã 6 số qua email, hiệu lực 15 phút, tối đa 5 lần nhập.
- Chỉnh sửa hồ sơ và ảnh đại diện: lưu trên server, đồng bộ giữa các thiết bị.
- Bảo mật và riêng tư: đổi/tạo mật khẩu, danh sách thành viên đã chặn, xóa ảnh khuôn mặt, xóa tài khoản vĩnh viễn (xóa mọi dữ liệu trên server).
- Thông báo: lịch nhắc hằng ngày lưu theo tài khoản; nhắc chỉ hoạt động khi app đang mở.
- Nhật ký & mục đã lưu: ghi nhật ký day huyệt, lưu huyệt yêu thích, xem các khóa học đã đăng ký.
- Trợ giúp: câu hỏi thường gặp, lưu bản nháp hỗ trợ trên thiết bị và sao chép nội dung.
- Đăng xuất: hủy phiên trên server và xóa dữ liệu phiên trên thiết bị.

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

## Cập nhật Vercel

Vercel phục vụ bản build có sẵn trong `dist`, không tự build Flutter. Chạy `flutter build web --release` trong `mobile`, đồng bộ `mobile/build/web/` sang `dist/` và `mobile/dist/`, rồi commit và push bản build. Kiểm tra `/release.json` trên website để xác nhận phiên bản triển khai.
