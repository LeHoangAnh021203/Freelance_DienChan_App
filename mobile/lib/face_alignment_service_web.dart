import 'dart:convert';
import 'dart:js_interop';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import 'face_alignment_result.dart';

@JS('dienChanFaceLandmarker.analyze')
external JSPromise<JSString> _analyzeFace(JSString dataUrl);

Future<FaceAlignmentResult> analyzeFacePhoto(XFile file) async {
  try {
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    final raw = (await _analyzeFace(dataUrl.toJS).toDart).toDart;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final box = data['box'] as Map<String, dynamic>?;
    final rect = box == null
        ? null
        : Rect.fromLTWH(
            (box['x'] as num).toDouble(),
            (box['y'] as num).toDouble(),
            (box['width'] as num).toDouble(),
            (box['height'] as num).toDouble(),
          );
    return FaceAlignmentResult(
      isValid: data['valid'] == true,
      message: data['message'] as String? ?? 'Không thể kiểm tra khuôn mặt.',
      faceRect: rect,
      imageSize: Size(
        (data['imageWidth'] as num?)?.toDouble() ?? 1,
        (data['imageHeight'] as num?)?.toDouble() ?? 1,
      ),
      yaw: (data['yaw'] as num?)?.toDouble() ?? 0,
      pitch: (data['pitch'] as num?)?.toDouble() ?? 0,
      roll: (data['roll'] as num?)?.toDouble() ?? 0,
    );
  } catch (_) {
    return const FaceAlignmentResult(
      isValid: false,
      message: 'Model nhận diện chưa tải xong. Kiểm tra mạng rồi thử lại.',
    );
  }
}
