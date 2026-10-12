import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dien_chan_app/bqc_digitized.dart';
import 'package:dien_chan_app/bqc_grid_reference.dart';
import 'package:dien_chan_app/face_3d_view.dart';
import 'package:dien_chan_app/bqc_source_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Observed dots replace shared cell centers and retain source provenance',
    () {
      expect(bqcDigitizedFront.length, 198);
      expect(bqcFrontPositions('556'), isNot(bqcFrontPositions('557')));
      expect(bqcFrontPositions('283'), isNotEmpty);
      expect(bqcFrontPositions('48'), isNotEmpty);
      for (final entry in bqcDigitizedFront.entries) {
        expect(bqcFrontSourceDots.containsKey(entry.key), isTrue);
        expect(bqcGridReferences.containsKey(entry.key), isTrue);
        for (final p in entry.value) {
          expect(p.dx, inInclusiveRange(0, 1));
          expect(p.dy, inInclusiveRange(0, 1));
        }
      }
      expect(bqcFrontPositions('46'), isEmpty);
      expect(bqcFrontPositions('55'), isEmpty);
      expect(bqcSideSourceDots['62'], isNotNull);
    },
  );
  test('Measured face landmarks remain on the 3D surface', () async {
    final mesh = FaceMesh.parse(
      await rootBundle.loadString('assets/models/canonical_face_model.obj'),
    );
    for (final code in [
      '8',
      '19',
      '26',
      '63',
      '87',
      '103',
      '106',
      '127',
      '179',
      '283',
      '73',
      '48',
    ]) {
      final points = bqcFrontPositions(
        code,
      ).map((p) => FacePoint(code, p, Colors.blue)).toList();
      expect(
        anchorFacePoints(mesh, points).length,
        points.length,
        reason: code,
      );
    }
  });
  testWidgets('Source view provides both original diagrams when observed', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BqcSourceView(code: '8')));
    expect(find.text('Chính diện · tr.154'), findsOneWidget);
    expect(find.text('Trắc diện · tr.155'), findsOneWidget);
    await tester.tap(find.text('Trắc diện · tr.155'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
