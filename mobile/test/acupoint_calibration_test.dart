import 'package:dien_chan_app/acupoint_calibration.dart';
import 'package:dien_chan_app/face_3d_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Calibrated midline positions map to the 3D surface', () async {
    final mesh = FaceMesh.parse(
      await rootBundle.loadString('assets/models/canonical_face_model.obj'),
    );
    final points = acupointCalibrations.entries
        .map((e) => FacePoint(e.key, e.value.normalized, Colors.blue))
        .toList();
    final anchors = anchorFacePoints(mesh, points);
    expect(
      anchors.map((a) => a.point.code).toSet(),
      acupointCalibrations.keys.toSet(),
    );
    for (final point in points) {
      expect(point.position.dx, 0.5);
    }
  });
  test(
    '2D diagram coordinates preserve image aspect ratio on different screens',
    () {
      for (final size in [const Size(400, 600), const Size(800, 400)]) {
        final rect = fittedFrontDiagram(size);
        expect(rect.width / rect.height, closeTo(864 / 1152, 1e-8));
        expect((rect.center - Offset(size.width / 2, size.height / 2)).distance, lessThan(1e-8));
      }
    },
  );
}
