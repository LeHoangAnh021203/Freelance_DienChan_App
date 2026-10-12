import 'package:dien_chan_app/face_3d_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Illustration mask excludes blank margins beside jaw and ears', () {
    expect(
      isInsideFaceIllustration(const Offset(432 / 864, 600 / 1152)),
      isTrue,
    );
    expect(
      isInsideFaceIllustration(const Offset(100 / 864, 750 / 1152)),
      isFalse,
    );
    expect(
      isInsideFaceIllustration(const Offset(750 / 864, 750 / 1152)),
      isFalse,
    );
    expect(
      isInsideFaceIllustration(const Offset(432 / 864, 1050 / 1152)),
      isFalse,
    );
  });

  test(
    'Profile projection anchors both sides and rejects outside surface',
    () async {
      final mesh = FaceMesh.parse(
        await rootBundle.loadString('assets/models/canonical_face_model.obj'),
      );
      final points = [
        for (final projection in [
          FacePointProjection.rightProfile,
          FacePointProjection.leftProfile,
        ])
          FacePoint(
            '60',
            const Offset(422 / 1368, 879 / 1824),
            Colors.red,
            projection: projection,
          ),
        const FacePoint(
          'outside',
          Offset(2, 2),
          Colors.red,
          projection: FacePointProjection.rightProfile,
        ),
      ];
      final anchors = anchorFacePoints(mesh, points);
      expect(anchors.length, 2);
      final positions = anchors
          .map(
            (a) => List.generate(
              3,
              (axis) => List.generate(
                3,
                (i) => mesh.vertices[a.triangle[i]][axis] * a.weights[i],
              ).reduce((a, b) => a + b),
            ),
          )
          .toList();
      expect(positions[0][0], greaterThan(0));
      expect(positions[1][0], lessThan(0));
      expect(positions[0][1], closeTo(positions[1][1], 1e-6));
      expect(positions[0][2], closeTo(positions[1][2], 1e-6));
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  test('Bundled face mesh has valid 3D geometry', () async {
    final mesh = FaceMesh.parse(
      await rootBundle.loadString('assets/models/canonical_face_model.obj'),
    );
    expect(mesh.vertices.length, 468);
    expect(mesh.triangles.length, greaterThan(800));
    expect(mesh.vertices.map((v) => v[2]).toSet().length, greaterThan(100));
    expect(() => FaceMesh.parse('v 0 0 0\nf 1 2 3'), throwsFormatException);
  });
  test(
    '3D anchors preserve source UV and reject points outside the surface',
    () async {
      final mesh = FaceMesh.parse(
        await rootBundle.loadString('assets/models/canonical_face_model.obj'),
      );
      final t = mesh.triangles.first;
      final uv =
          t
              .map((i) => faceDrawingUV(mesh.vertices[i]))
              .reduce((a, b) => a + b) /
          3;
      final anchors = anchorFacePoints(mesh, [
        FacePoint('test', uv, Colors.red),
        const FacePoint('outside', Offset(-1, -1), Colors.blue),
      ]);
      expect(anchors.length, 1);
      final anchor = anchors.single;
      var reconstructed = Offset.zero;
      for (var i = 0; i < 3; i++) {
        reconstructed +=
            faceDrawingUV(mesh.vertices[anchor.triangle[i]]) *
            anchor.weights[i];
      }
      expect((uv - reconstructed).distance, lessThan(1e-6));
    },
  );
  testWidgets('3D viewer loads, rotates, zooms and resets', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: Face3DPage()));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('face-3d-gesture')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('face-3d-gesture')),
      const Offset(70, 30),
    );
    expect(find.text('Góc trái'), findsNothing);
    expect(find.text('Nét vẽ 2D'), findsNothing);
    expect(find.textContaining('Ngoài bề mặt 3D:'), findsNothing);
    final gesture = find.byKey(const ValueKey('face-3d-gesture'));
    await tester.tap(gesture);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(gesture);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
