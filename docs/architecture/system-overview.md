# System Overview

Dien Chan App được tổ chức theo hướng monorepo:

- `mobile/`: client cho người dùng cuối.
- `backend/`: API quản lý dữ liệu huyệt, bệnh, phác đồ và nhật ký.
- `docs/`: tài liệu nghiệp vụ và kỹ thuật.
- `infra/`: script, môi trường và cấu hình triển khai.

## Data Flow

1. Người dùng nhập triệu chứng hoặc chọn chức năng.
2. Client tìm kiếm trong danh mục bệnh/triệu chứng.
3. Hệ thống đề xuất phác đồ phù hợp.
4. Người dùng xem từng bước tác động huyệt.
5. Nhật ký ghi lại cảm nhận, mức độ cải thiện và ghi chú.

## Safety Boundary

Ứng dụng chỉ nên đóng vai trò hỗ trợ chăm sóc sức khỏe. Các tình huống có cảnh báo nguy hiểm phải hướng người dùng đi khám hoặc liên hệ y tế.
