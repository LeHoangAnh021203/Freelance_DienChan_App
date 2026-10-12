# Hiệu chỉnh mốc trên hình mẫu

Nguồn đọc trực tiếp 11/10/2026: https://dienchan.com/cap-nhat-bo-huyet-moc-bqc-va-do-hinh-bo-huyet-bqc-dien-chan-dieu-khien-lieu-phap

Bài Việt Y Đạo giới thiệu cập nhật huyệt mốc BQC tháng 10/2016. Có bảng định vị; đường dẫn ảnh chính diện/nghiêng cũ chưa truy cập được qua công cụ web.

Đã căn 8 điểm đường giữa: 8, 19, 26, 63, 87, 103, 106, 127. Mô tả nguồn và tọa độ ảnh riêng biệt trong `mobile/lib/acupoint_calibration.dart`. Điểm 63 được thêm vì thiếu trong danh mục. Những số pixel là căn chỉnh thủ công trên ảnh minh họa 864×1152 của project, không phải tọa độ tác giả xuất bản, không phải tỉ lệ chuẩn lâm sàng.

Cùng tọa độ chuẩn hóa được dùng cho 2D và ánh xạ tam giác 3D. Sửa khung vẽ điểm 2D theo BoxFit.contain để không trượt khi đổi tỉ lệ màn hình. Chưa hiệu chỉnh phép suy ra mặt nghiêng, ảnh người dùng, các điểm hai bên và phần ngoài lưới. Tất cả vẫn cần duyệt chuyên môn.

Bảng nguồn có một chỗ cần đối chiếu lại: mô tả huyệt 26 và giá trị tuyến ngang đi kèm không nhất quán với vị trí lông mày. Dự án chỉ dùng mô tả giải phẫu, chưa đưa giá trị tuyến này vào phép tính.

Tài liệu tương tự cùng tác giả được xác định qua thư mục: *Tuyển tập đồ hình Diện Chẩn điều khiển liệu pháp & xoa bóp Việt Nam*. Hồ sơ Google Books: https://books.google.com/books/about/Tuyen_Tap_Do_Hinh_Dien_Chan_Dieu_Khien_L.html?id=bk6JMwEACAAJ . Chưa đọc toàn văn nên không dùng làm căn cứ tọa độ.
