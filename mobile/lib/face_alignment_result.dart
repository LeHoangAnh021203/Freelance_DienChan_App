import 'package:flutter/material.dart';

import 'app_locale.dart';

class FaceAlignmentResult {
  const FaceAlignmentResult({
    required this.isValid,
    required this.message,
    this.faceRect,
    this.imageSize,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
  });

  final bool isValid;
  final String message;
  final Rect? faceRect;
  final Size? imageSize;
  final double yaw;
  final double pitch;
  final double roll;

  String get localizedMessage => localizeAlignmentMessage(message);

  static const unavailable = FaceAlignmentResult(
    isValid: false,
    message: 'Không thể phân tích khuôn mặt trên thiết bị này.',
  );
}

const _alignmentMessageEn = <String, String>{
  'Không thấy khuôn mặt. Hãy nhìn thẳng vào camera.':
      'No face found. Look straight at the camera.',
  'Chỉ để một khuôn mặt trong khung hình.':
      'Keep only one face in the frame.',
  'Không đọc được khuôn mặt. Hãy chụp lại trong điều kiện đủ sáng.':
      'Could not read the face. Retake the photo in better light.',
  'Đưa khuôn mặt lại gần camera hơn.': 'Move your face closer to the camera.',
  'Đưa khuôn mặt ra xa camera một chút.':
      'Move your face a little farther from the camera.',
  'Đưa khuôn mặt vào chính giữa khung.': 'Center your face in the frame.',
  'Giữ đầu thẳng, không nghiêng hoặc quay sang hai bên.':
      'Keep your head straight — no tilt or turn.',
  'Khuôn mặt đạt yêu cầu và đã sẵn sàng đặt huyệt.':
      'Face looks good and is ready for point placement.',
  'Không thể phân tích khuôn mặt trên thiết bị này.':
      'Face analysis is not available on this device.',
  'Không thể kiểm tra khuôn mặt.': 'Could not check the face.',
  'Model nhận diện chưa tải xong. Kiểm tra mạng rồi thử lại.':
      'Face model is still loading. Check your network and try again.',
};

String localizeAlignmentMessage(String message) =>
    tr(message, _alignmentMessageEn[message] ?? message);
