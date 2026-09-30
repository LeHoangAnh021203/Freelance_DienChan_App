import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_alignment_result.dart';

Future<FaceAlignmentResult> analyzeFacePhoto(XFile file) async {
  final detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  try {
    final bytes = await file.readAsBytes();
    final image = await _decodeImage(bytes);
    final faces = await detector.processImage(
      InputImage.fromFilePath(file.path),
    );
    if (faces.isEmpty) {
      return const FaceAlignmentResult(
        isValid: false,
        message: 'Không thấy khuôn mặt. Hãy nhìn thẳng vào camera.',
      );
    }
    if (faces.length != 1) {
      return const FaceAlignmentResult(
        isValid: false,
        message: 'Chỉ để một khuôn mặt trong khung hình.',
      );
    }

    final face = faces.first;
    final rect = Rect.fromLTRB(
      (face.boundingBox.left / image.width).clamp(0.0, 1.0),
      (face.boundingBox.top / image.height).clamp(0.0, 1.0),
      (face.boundingBox.right / image.width).clamp(0.0, 1.0),
      (face.boundingBox.bottom / image.height).clamp(0.0, 1.0),
    );
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    return _validate(
      rect,
      imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      yaw: yaw,
      pitch: pitch,
      roll: roll,
    );
  } catch (_) {
    return const FaceAlignmentResult(
      isValid: false,
      message:
          'Không đọc được khuôn mặt. Hãy chụp lại trong điều kiện đủ sáng.',
    );
  } finally {
    await detector.close();
  }
}

Future<ui.Image> _decodeImage(List<int> bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(Uint8List.fromList(bytes), completer.complete);
  return completer.future;
}

FaceAlignmentResult _validate(
  Rect rect, {
  required Size imageSize,
  required double yaw,
  required double pitch,
  required double roll,
}) {
  final centerError = (rect.center - const Offset(0.5, 0.46)).distance;
  if (rect.width < 0.32 || rect.height < 0.38) {
    return FaceAlignmentResult(
      isValid: false,
      message: 'Đưa khuôn mặt lại gần camera hơn.',
      faceRect: rect,
      imageSize: imageSize,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
    );
  }
  if (rect.width > 0.78 || rect.height > 0.82) {
    return FaceAlignmentResult(
      isValid: false,
      message: 'Đưa khuôn mặt ra xa camera một chút.',
      faceRect: rect,
      imageSize: imageSize,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
    );
  }
  if (centerError > 0.12) {
    return FaceAlignmentResult(
      isValid: false,
      message: 'Đưa khuôn mặt vào chính giữa khung.',
      faceRect: rect,
      imageSize: imageSize,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
    );
  }
  if (yaw.abs() > 10 || pitch.abs() > 10 || roll.abs() > 7) {
    return FaceAlignmentResult(
      isValid: false,
      message: 'Giữ đầu thẳng, không nghiêng hoặc quay sang hai bên.',
      faceRect: rect,
      imageSize: imageSize,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
    );
  }
  return FaceAlignmentResult(
    isValid: true,
    message: 'Khuôn mặt đạt yêu cầu và đã sẵn sàng đặt huyệt.',
    faceRect: rect,
    imageSize: imageSize,
    yaw: yaw,
    pitch: pitch,
    roll: roll,
  );
}
