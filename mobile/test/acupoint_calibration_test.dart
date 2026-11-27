import 'package:dien_chan_app/acupoint_calibration.dart';
import 'package:dien_chan_app/bqc_digitized.dart';
import 'package:dien_chan_app/bqc_grid_reference.dart';
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
  test('Location labels distinguish nearby acupoints in Vietnamese', () {
    expect(acupointLocationLabel('26'), 'Giữa hai lông mày');
    expect(acupointLocationLabel('14'), 'Sau tai');
    expect(acupointLocationLabel('55'), 'Sau tai');
    expect(acupointLocationLabel('0').toLowerCase(), contains('mặt bên'));
    expect(acupointLocationLabel('62'), contains('môi trên'));
    expect(acupointLocationLabel('0'), isNot(acupointLocationLabel('62')));
    expect(
      acupointLocationLabel('1').toLowerCase(),
      contains('đường giữa mặt'),
    );
    expect(acupointLocationLabel('37'), contains('phải'));
    expect(acupointLocationLabel('41'), contains('trái'));
    expect(acupointLocationLabel('unknown'), 'Huyệt unknown trên gương mặt');
  });

  test(
    'Every tabulated point has a friendly location, not a table citation',
    () {
      for (final code in bqcGridReferences.keys) {
        final label = acupointLocationLabel(code);
        expect(label, isNotEmpty, reason: code);
        expect(label, isNot(contains('Bảng tr.')), reason: code);
      }
    },
  );

  test(
    '2D diagram coordinates preserve image aspect ratio on different screens',
    () {
      for (final size in [const Size(400, 600), const Size(800, 400)]) {
        final rect = fittedFrontDiagram(size);
        expect(rect.width / rect.height, closeTo(864 / 1152, 1e-8));
        expect(
          (rect.center - Offset(size.width / 2, size.height / 2)).distance,
          lessThan(1e-8),
        );
        expect(fittedSideDiagram(size), rect);
      }
    },
  );

  test('BQC front grid keeps midline O and eyebrow row IV', () {
    final columns = bqcFrontGridColumns();
    expect(columns.where((c) => c.label == 'O').single.x, 0.5);
    final rows = bqcFrontGridRows();
    expect(rows.map((r) => r.label), containsAll(['O', 'IV', 'V', 'XII']));
    final iv = rows.firstWhere((r) => r.label == 'IV').y;
    // Huyệt 26 (giữa hai lông mày) sits on row IV in the digitized plate.
    expect(bqcFrontPositions('26').single.dy, closeTo(iv, 0.02));
  });

  test('Side-only points such as 0 exist for the profile diagram', () {
    expect(bqcSideSourceDots.containsKey('0'), isTrue);
    expect(bqcSidePositions('0'), isNotEmpty);
    expect(bqcFrontPositions('0'), isEmpty);
    // User-ref diagram: huyệt 0 near ear, not the nose.
    final side0 = bqcSidePositions('0').single;
    expect(side0.dx, greaterThan(0.45));
    // SAU TAI inset points digitized from the user reference screenshot.
    for (final code in ['14', '15', '54', '55', '56', '200', '204']) {
      expect(bqcDigitizedSide.containsKey(code), isTrue, reason: code);
      expect(bqcSidePositions(code), isNotEmpty, reason: code);
    }
    final rows = bqcSideGridRows();
    expect(rows.first.label, 'O');
    expect(rows.last.label, 'XII');
    final cols = bqcSideGridColumns();
    expect(cols.map((c) => c.label).toList(), ['L', 'M', 'N', 'P', 'Q']);
    for (var i = 1; i < cols.length; i++) {
      expect(cols[i].x, greaterThan(cols[i - 1].x));
    }
  });
}
