# Backend

Thư mục dành cho API và business services của Dien Chan App.

## Planned Modules

- `auth`: đăng nhập, hồ sơ người dùng, phân quyền.
- `users`: thông tin cá nhân, tùy chọn giao diện, preset.
- `acupoints`: danh mục huyệt và vị trí trên đồ hình.
- `conditions`: bệnh, triệu chứng, nhóm bệnh và từ khóa tìm kiếm.
- `protocols`: phác đồ, bước tác động, cảnh báo an toàn.
- `journals`: bệnh án cá nhân, lịch sử thực hành, phản hồi hiệu quả.

## Current Status

Backend hiện dùng Node.js built-in modules, không cần cài dependency. Dữ liệu local nằm trong `backend/data/store.json`.

## Run

Từ root repo:

```bash
npm run dev
```

## API Contract

Xem `docs/api/` để biết các endpoint dự kiến.
