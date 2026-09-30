import 'package:flutter/material.dart';

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

  static const unavailable = FaceAlignmentResult(
    isValid: false,
    message: 'Không thể phân tích khuôn mặt trên thiết bị này.',
  );
}
