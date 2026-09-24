# PostgreSQL Schema Draft

## Tables

- `users`
- `acupoints`
- `conditions`
- `condition_keywords`
- `protocols`
- `protocol_conditions`
- `protocol_steps`
- `reflex_maps`
- `touch_points`
- `principles`
- `tools`
- `acupoint_tools`
- `journals`
- `tracking_records`
- `tracking_entries`
- `bookmarks`
- `user_settings`
- `product_spec`

## Notes

- Dùng PostgreSQL làm source of truth cho dữ liệu nghiệp vụ.
- Các trường tọa độ đồ hình nên lưu dạng số thực trong khoảng `0..1`.
- Từ khóa tìm kiếm nên tách bảng để dễ mở rộng và chuẩn hóa.
- Bệnh án là dữ liệu sức khỏe nhạy cảm, mặc định lưu on-device; chỉ đồng bộ khi user bật.
