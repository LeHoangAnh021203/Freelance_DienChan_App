# Nghiên cứu đồ hình khuôn mặt 3D

Ngày đối chiếu nguồn: 2026-10-11. Trạng thái: nghiên cứu và đề xuất, chưa tích hợp mô hình 3D vào app.

## Hiện trạng dự án

- `mobile/lib/main.dart`: ảnh mặt trước/mặt nghiêng và lớp điểm 2D, hiện cùng nằm trong InteractiveViewer.
- `mobile/web/face_landmarker.js`: đã dùng MediaPipe FaceLandmarker nhưng chỉ trả khung bao, góc đầu, kích thước ảnh; chưa truyền toàn bộ landmarks sang Dart.
- `FaceAlignmentResult` chưa chứa lưới hoặc các điểm 3D.
- Bản native dùng ML Kit Face Detection, chưa tương đương pipeline lưới MediaPipe trên web.
- Chưa có asset 3D, dữ liệu tọa độ huyệt 3D hoặc bộ kiểm chứng vị trí huyệt.

## Mô hình và công cụ phù hợp

| Thành phần | Nguồn chính thức | Vai trò và giới hạn |
|---|---|---|
| MediaPipe Face Landmarker | https://developers.google.com/edge/mediapipe/solutions/vision/face_landmarker | Ước lượng 478 mốc 3D từ ảnh/video; không phải bộ nhận diện huyệt. |
| Canonical face model OBJ | https://github.com/google-ai-edge/mediapipe/blob/master/mediapipe/modules/face_geometry/data/canonical_face_model.obj | Lưới chuẩn để thử dựng mặt, ánh sáng, xoay, gắn điểm; không thay thế mô hình đầy đủ đầu/tai/gáy. |
| Face Geometry | https://github.com/google-ai-edge/mediapipe/blob/master/docs/solutions/face_mesh.md | Hệ tọa độ, canonical mesh và phép biến đổi. Cần kiểm tra mapping topology: mesh chuẩn 468 điểm không có đầy đủ 478 điểm của đầu ra mới. |
| FLAME 2023 Open | https://flame.is.tue.mpg.de/ | Ứng viên cho mô hình đầu có hình dạng/biểu cảm. Trang dự án công bố bản Open CC-BY-4.0; các bản trước có điều khoản khác. Không đồng nhất giấy phép model, texture và các pipeline dựng mặt bên thứ ba. |
| model-viewer | https://modelviewer.dev/examples/annotations/ | Có hotspot theo vị trí/pháp tuyến và bám bề mặt. Kiểm tra che khuất thực tế: hướng pháp tuyến không đủ để xác định bị mũi/má che. |
| model_viewer_plus | https://pub.dev/packages/model_viewer_plus | Ứng viên nhúng GLB/glTF trong Flutter; phải thử tương thích Dart 3.11.1 và tương tác chạm trước khi thêm dependency. |

MediaPipe repository: https://github.com/google-ai-edge/mediapipe/blob/master/LICENSE
Model card: https://storage.googleapis.com/mediapipe-assets/Model%20Card%20MediaPipe%20Face%20Mesh%20V2.pdf

## Đề xuất triển khai

1. Làm đồ hình 3D chuẩn trước: một khuôn mặt trung tính, xoay ngang/dọc, zoom, góc chính diện/nghiêng và nút đặt lại. Giữ đồ hình 2D để đối chiếu và dự phòng.
2. Prototype bằng canonical OBJ; chuyển GLB cho viewer. Đây là mô hình thử nghiệm hình học, không công bố như bản đồ huyệt đã kiểm chứng.
3. Với bản trực quan đầy đủ hơn, đánh giá FLAME 2023 Open, kiểm tra vùng tai/đầu cần hiển thị và chuẩn bị vật liệu trung tính. Khóa phiên bản mesh trước khi gắn huyệt.
4. Tạo công cụ gắn huyệt lên tam giác bề mặt. Lưu mã huyệt, phía trái/phải, triangle ID, trọng số barycentric, phiên bản mesh, nguồn tài liệu, người duyệt và trạng thái xác nhận. Không gán thẳng mã huyệt vào index landmark AI.
5. Lựa chọn 10–20 huyệt có tài liệu định vị rõ để thử; đối chiếu đồng thời góc trước và nghiêng với người phụ trách chuyên môn. Chưa tự chuyển toàn bộ tọa độ ảnh 2D sang 3D.
6. Cá nhân hóa sau: truyền landmarks và matrix từ MediaPipe; thống nhất tọa độ, ảnh soi gương và topology. Mốc 3D từ một ảnh là ước lượng, không chứng minh hình dạng chính xác ở vùng bị che.
7. Native cần pipeline tương đương nếu muốn cùng khả năng cá nhân hóa; không coi ML Kit bounding box là lưới 3D.

## Tiêu chí chất lượng đề xuất

- Kéo/zoom không làm điểm trượt khỏi bề mặt; bấm huyệt hiện đúng mã và mô tả.
- Không hiển thị điểm phía sau xuyên qua mặt; raycast/depth test nếu viewer không đáp ứng.
- Không nhầm trái/phải khi dùng camera trước hoặc ảnh lật gương.
- Đo sai lệch so với dữ liệu chuyên gia trên nhiều góc và hình dạng mặt; báo cáo trung vị, phân vị 95 và trường hợp thất bại. Chỉ báo đơn vị mm khi có dữ liệu kích thước đã hiệu chuẩn.
- Đánh giá vùng mắt, mũi, môi, cằm và phần bị che riêng. Không nội suy các vùng ngoài phạm vi mesh như thể đã được quan sát.
- Mục tiêu kỹ thuật thử nghiệm: ít nhất 30 FPS trên thiết bị mục tiêu, tải model có tiến trình, có fallback 2D khi WebGL không khả dụng. Chưa có số đo hiệu năng thực tế.
- Ghim phiên bản thư viện và model, lưu license/attribution cùng asset. Script MediaPipe hiện dùng @latest, cần thay bằng phiên bản đã kiểm thử khi triển khai.

## Kết luận

Có thể xây dựng khuôn mặt 3D tương tác. Hướng khuyến nghị là đồ hình 3D chuẩn được gắn và duyệt huyệt trước, sau đó mới cá nhân hóa theo ảnh người dùng. Tính sinh động đến từ dựng hình; độ chính xác phải được chứng minh bằng dữ liệu định vị và kiểm thử độc lập. Nghiên cứu này chưa tìm được bộ tọa độ huyệt Diện Chẩn 3D đã kiểm chứng để nhập trực tiếp.
