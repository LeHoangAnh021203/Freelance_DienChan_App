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

### Flutter app

```bash
cd mobile
flutter pub get
flutter run
```

Chạy web Flutter:

```bash
cd mobile
flutter run -d chrome
```

### Backend/API local

```bash
npm run dev
```

Sau đó API ở:

```text
http://127.0.0.1:5173/api/v1/health
```

### Legacy web prototype

```bash
cd mobile/legacy-web
python3 -m http.server 5173
```

## Suggested Next Steps

1. Tách dữ liệu mẫu trong `mobile/web/app.js` sang JSON hoặc API.
2. Chọn backend framework và bootstrap trong `backend/`.
3. Chuẩn hóa database schema cho huyệt, bệnh, triệu chứng, phác đồ và nhật ký.
4. Kết nối client với API thật.
