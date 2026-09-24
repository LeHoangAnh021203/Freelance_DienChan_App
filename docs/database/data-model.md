# Data Model

## Core Entities

- `users`
- `acupoints`
- `conditions`
- `protocols`
- `protocol_steps`
- `reflex_maps`
- `touch_points`
- `principles`
- `tools`
- `journals`
- `tracking_records`
- `bookmarks`
- `user_settings`
- `product_spec`

## Relationships

- `conditions` liên kết nhiều `protocols`.
- `protocols` có nhiều `protocol_steps`.
- `protocol_steps` tham chiếu `acupoints`.
- `touch_points` tham chiếu `reflex_maps` và `acupoints`.
- `acupoints` có thể gợi ý nhiều `tools`.
- `journals` tham chiếu `users`, tùy chọn tham chiếu `conditions` và `protocols`.
- `tracking_records` tham chiếu vấn đề sức khỏe đang theo dõi và chứa các entry nhật ký.
- `bookmarks` lưu id huyệt, phác đồ hoặc dụng cụ kèm thời điểm lưu.
