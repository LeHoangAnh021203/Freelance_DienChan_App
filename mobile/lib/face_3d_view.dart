import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A bundled 3D surface, independent of camera permissions or network access.
class FaceMesh {
  FaceMesh(this.vertices, this.triangles);
  final List<List<double>> vertices;
  final List<List<int>> triangles;

  factory FaceMesh.parse(String obj) {
    final vertices = <List<double>>[];
    final triangles = <List<int>>[];
    for (final line in obj.split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.first == 'v' && parts.length >= 4) {
        vertices.add(parts.skip(1).take(3).map(double.parse).toList());
      } else if (parts.first == 'f' && parts.length >= 4) {
        final face = parts
            .skip(1)
            .map((p) => int.parse(p.split('/').first) - 1)
            .toList();
        for (var i = 1; i < face.length - 1; i++) {
          triangles.add([face[0], face[i], face[i + 1]]);
        }
      }
    }
    if (vertices.isEmpty ||
        triangles.isEmpty ||
        vertices.any((v) => v.any((n) => !n.isFinite)) ||
        triangles.any((t) => t.any((i) => i < 0 || i >= vertices.length))) {
      throw const FormatException('Invalid face mesh');
    }
    return FaceMesh(vertices, triangles);
  }
}

class Face3DPage extends StatefulWidget {
  const Face3DPage({
    super.key,
    this.embedded = false,
    this.onShow2D,
    this.markers = const [],
    this.highlightCode,
    this.showLabels = false,
  });
  final List<FacePoint> markers;
  final String? highlightCode;
  final bool showLabels;
  final bool embedded;
  final VoidCallback? onShow2D;
  @override
  State<Face3DPage> createState() => _Face3DPageState();
}

class _Face3DPageState extends State<Face3DPage> {
  late Future<FaceMesh> _mesh;
  double _yaw = 0, _pitch = 0, _zoom = 1, _startZoom = 1;
  final bool _wire = false;
  ui.Image? _drawing;
  int _loadGeneration = 0;
  List<double>? _focus;
  FaceMesh? _loadedMesh;

  @override
  void didUpdateWidget(covariant Face3DPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightCode != widget.highlightCode) _focusSelection();
  }

  void _focusSelection() {
    final mesh = _loadedMesh;
    _focus = null;
    if (mesh == null || widget.highlightCode == null) return;
    final anchors = anchorFacePoints(
      mesh,
      widget.markers.where((p) => p.code == widget.highlightCode).toList(),
    );
    for (final anchor in anchors) {
      final uv = List.generate(
        3,
        (i) =>
            faceDrawingUV(mesh.vertices[anchor.triangle[i]]) *
            anchor.weights[i],
      ).reduce((a, b) => a + b);
      if (!isInsideFaceIllustration(uv)) continue;
      _focus = List.generate(
        3,
        (axis) => List.generate(
          3,
          (i) => mesh.vertices[anchor.triangle[i]][axis] * anchor.weights[i],
        ).reduce((a, b) => a + b),
      );
      _yaw = (-math.atan2(_focus![0], _focus![2])).clamp(-1.1, 1.1);
      _pitch = 0;
      _zoom = 2.2;
      break;
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _drawing?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final generation = ++_loadGeneration;
    _mesh = () async {
      final mesh = FaceMesh.parse(
        await rootBundle.loadString('assets/models/canonical_face_model.obj'),
      );
      final bytes = await rootBundle.load(
        'assets/images/dienchan_face_front.png',
      );
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      try {
        final frame = await codec.getNextFrame();
        if (!mounted || generation != _loadGeneration) {
          frame.image.dispose();
        } else {
          _drawing?.dispose();
          _drawing = frame.image;
        }
      } finally {
        codec.dispose();
      }
      _loadedMesh = mesh;
      _focusSelection();
      return mesh;
    }();
  }

  void _reset() => setState(() {
    _yaw = 0;
    _pitch = 0;
    _zoom = 1;
    _focus = null;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded
        ? null
        : AppBar(
            title: const Text('Khuôn mặt 3D'),
            actions: [
              IconButton(
                tooltip: 'Đặt lại góc nhìn',
                onPressed: _reset,
                icon: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<FaceMesh>(
              future: _mesh,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Không tải được mô hình 3D.'),
                        TextButton(
                          onPressed: () => setState(_load),
                          child: const Text('Thử lại'),
                        ),
                        TextButton(
                          onPressed:
                              widget.onShow2D ?? () => Navigator.pop(context),
                          child: const Text('Về đồ hình 2D'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    Expanded(
                      child: Semantics(
                        label:
                            'Mô hình khuôn mặt 3D. Kéo để xoay, chụm hai ngón để phóng to.',
                        child: GestureDetector(
                          key: const ValueKey('face-3d-gesture'),
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: _reset,
                          onScaleStart: (_) => _startZoom = _zoom,
                          onScaleUpdate: (details) => setState(() {
                            _yaw = (_yaw + details.focalPointDelta.dx * 0.01)
                                .clamp(-1.48, 1.48);
                            _pitch =
                                (_pitch + details.focalPointDelta.dy * 0.01)
                                    .clamp(-0.85, 0.85);
                            _zoom = (_startZoom * details.scale).clamp(
                              0.65,
                              2.5,
                            );
                          }),
                          child: CustomPaint(
                            painter: _FaceMeshPainter(
                              snapshot.data!,
                              _yaw,
                              _pitch,
                              _zoom,
                              _wire,
                              _drawing,
                              widget.markers,
                              widget.highlightCode,
                              widget.showLabels,
                              _focus,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Text(
            'Kéo để xoay · Chụm để thu phóng · Chạm hai lần để đặt lại',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _FaceMeshPainter extends CustomPainter {
  _FaceMeshPainter(
    this.mesh,
    this.yaw,
    this.pitch,
    this.zoom,
    this.wire,
    this.drawing,
    this.markers,
    this.highlightCode,
    this.showLabels,
    this.focus,
  );
  final List<double>? focus;
  final List<FacePoint> markers;
  final String? highlightCode;
  final bool showLabels;
  final ui.Image? drawing;
  final FaceMesh mesh;
  final double yaw, pitch, zoom;
  final bool wire;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final scale = math.min(size.width / 20, size.height / 25) * zoom;
    final center = Offset(size.width / 2, size.height / 2);
    final points = mesh.vertices.map((v) {
      final x = v[0], y = v[1] + 0.5, z = v[2] - 3;
      final rx = x * math.cos(yaw) + z * math.sin(yaw);
      final rz = -x * math.sin(yaw) + z * math.cos(yaw);
      return [
        rx,
        y * math.cos(pitch) - rz * math.sin(pitch),
        y * math.sin(pitch) + rz * math.cos(pitch),
      ];
    }).toList();
    final triangles = List<List<int>>.of(mesh.triangles)
      ..sort(
        (a, b) => (points[a[0]][2] + points[a[1]][2] + points[a[2]][2])
            .compareTo(points[b[0]][2] + points[b[1]][2] + points[b[2]][2]),
      );
    var focusOffset = Offset.zero;
    if (focus case final target?) {
      final x = target[0], y = target[1] + 0.5, z = target[2] - 3;
      final rx = x * math.cos(yaw) + z * math.sin(yaw);
      final rz = -x * math.sin(yaw) + z * math.cos(yaw);
      final ry = y * math.cos(pitch) - rz * math.sin(pitch);
      final depth = y * math.sin(pitch) + rz * math.cos(pitch);
      focusOffset = Offset(rx, -ry) * (scale * 40 / (40 - depth));
    }
    Offset project(List<double> v) {
      final perspective = 40 / (40 - v[2]);
      return center -
          focusOffset +
          Offset(v[0] * scale * perspective, -v[1] * scale * perspective);
    }

    final texture = drawing;
    final texturePaint = texture == null
        ? null
        : (Paint()
            ..filterQuality = FilterQuality.medium
            ..shader = ui.ImageShader(
              texture,
              TileMode.clamp,
              TileMode.clamp,
              Matrix4.identity().storage,
            ));
    // Hand-aligned frontal illustration anchors, not anatomical calibration.
    Offset texturePoint(int index) {
      final uv = faceDrawingUV(mesh.vertices[index]);
      return Offset(uv.dx * texture!.width, uv.dy * texture.height);
    }

    final anchors = anchorFacePoints(mesh, markers);
    final occupiedLabels = <Rect>[];
    final codes = markers.map((p) => p.code).toSet().toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    final colors = {
      for (var i = 0; i < codes.length; i++)
        codes[i]: i.isEven ? const Color(0xFFE53935) : const Color(0xFF3299C4),
    };

    for (final t in triangles) {
      final a = points[t[0]], b = points[t[1]], c = points[t[2]];
      final pa = project(a), pb = project(b), pc = project(c);
      final path = Path()
        ..moveTo(pa.dx, pa.dy)
        ..lineTo(pb.dx, pb.dy)
        ..lineTo(pc.dx, pc.dy)
        ..close();
      // White paper surface preserves the original 2D illustration style.
      canvas.drawPath(path, Paint()..color = Colors.white);
      if (texturePaint != null) {
        final vertices = ui.Vertices(
          ui.VertexMode.triangles,
          [pa, pb, pc],
          textureCoordinates: t.map(texturePoint).toList(),
        );
        canvas.drawVertices(vertices, BlendMode.src, texturePaint);
        vertices.dispose();
      }
      for (final anchor in anchors.where((a) => identical(a.triangle, t))) {
        final illustrationPosition = List.generate(
          3,
          (i) =>
              faceDrawingUV(mesh.vertices[anchor.triangle[i]]) *
              anchor.weights[i],
        ).reduce((a, b) => a + b);
        if (!isInsideFaceIllustration(illustrationPosition)) continue;
        final position = List<double>.generate(
          3,
          (axis) =>
              a[axis] * anchor.weights[0] +
              b[axis] * anchor.weights[1] +
              c[axis] * anchor.weights[2],
        );
        final spot = project(position);
        final active = anchor.point.code == highlightCode;
        canvas.drawCircle(
          spot,
          active ? 6 : 3.5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          spot,
          active ? 4.5 : 2.5,
          Paint()..color = active ? Colors.red : colors[anchor.point.code]!,
        );
        if (showLabels || active) {
          final label = TextPainter(
            text: TextSpan(
              text: anchor.point.code,
              style: TextStyle(
                fontSize: active ? 13 : 9,
                color: Colors.black,
                backgroundColor: const Color(0xDDFFFFFF),
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final origin = spot + const Offset(5, -12);
          final bounds = (origin & label.size).inflate(2);
          // Keep the selected code readable; suppress crowded passive labels.
          if (active || !occupiedLabels.any((rect) => rect.overlaps(bounds))) {
            label.paint(canvas, origin);
            occupiedLabels.add(bounds);
          }
        }
      }
      if (wire) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0x6673442D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FaceMeshPainter old) =>
      old.focus != focus ||
      old.markers != markers ||
      old.highlightCode != highlightCode ||
      old.showLabels != showLabels ||
      old.drawing != drawing ||
      old.mesh != mesh ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.zoom != zoom ||
      old.wire != wire;
}

Offset faceDrawingUV(List<double> v) {
  const rows = [
    [8.27, 260.0, 43.0],
    [2.66, 500.0, 49.5],
    [-1.13, 685.0, 45.0],
    [-4.34, 810.0, 39.0],
    [-9.41, 995.0, 40.0],
  ];
  var y = rows.last[1];
  var xScale = rows.last[2];
  for (var i = 0; i < rows.length - 1; i++) {
    if (v[1] >= rows[i + 1][0]) {
      final f = ((rows[i][0] - v[1]) / (rows[i][0] - rows[i + 1][0])).clamp(
        0.0,
        1.0,
      );
      y = rows[i][1] + (rows[i + 1][1] - rows[i][1]) * f;
      xScale = rows[i][2] + (rows[i + 1][2] - rows[i][2]) * f;
      break;
    }
  }
  return Offset((432 + v[0] * xScale) / 864, y / 1152);
}

enum FacePointProjection { front, rightProfile, leftProfile }

/// Approximate registration of the photographed profile to canonical depth/height.
/// Coordinates are graphical estimates, not clinically validated positions.
Offset profilePhotoToPlane(Offset photo) {
  const rows = [
    [465.0, 8.27, 254.0, 4.48],
    [817.0, 2.66, 207.0, 5.0],
    [1035.0, -1.13, 76.0, 7.48],
    [1164.0, -4.34, 137.0, 5.0],
    [1425.0, -9.41, 220.0, 4.26],
  ];
  final x = photo.dx * 1368, y = photo.dy * 1824;
  if (y < rows.first[0] || y > rows.last[0]) return const Offset(999, 999);
  for (var i = 0; i < rows.length - 1; i++) {
    final a = rows[i], b = rows[i + 1];
    if (y <= b[0]) {
      final f = (y - a[0]) / (b[0] - a[0]);
      final height = a[1] + f * (b[1] - a[1]);
      final frontX = a[2] + f * (b[2] - a[2]);
      final frontZ = a[3] + f * (b[3] - a[3]);
      return Offset(frontZ - (x - frontX) / 48, height);
    }
  }
  return const Offset(999, 999);
}

class FacePoint {
  const FacePoint(
    this.code,
    this.position,
    this.color, {
    this.projection = FacePointProjection.front,
  });
  final FacePointProjection projection;
  final String code;
  final Offset position;
  final Color color;
}

class FacePointAnchor {
  const FacePointAnchor(this.point, this.triangle, this.weights);
  final FacePoint point;
  final List<int> triangle;
  final List<double> weights;
}

List<FacePointAnchor> anchorFacePoints(FaceMesh mesh, List<FacePoint> points) {
  final uv = mesh.vertices.map(faceDrawingUV).toList();
  final result = <FacePointAnchor>[];
  for (final point in points) {
    final profile = point.projection != FacePointProjection.front;
    final coordinates = profile
        ? mesh.vertices.map((v) => Offset(v[2], v[1])).toList()
        : uv;
    final position = profile
        ? profilePhotoToPlane(point.position)
        : point.position;
    FacePointAnchor? best;
    var outermost = -double.infinity;
    for (final t in mesh.triangles) {
      final sign = point.projection == FacePointProjection.leftProfile ? -1 : 1;
      if (profile && t.any((i) => mesh.vertices[i][0] * sign < -1e-6)) continue;
      final a = coordinates[t[0]],
          b = coordinates[t[1]],
          c = coordinates[t[2]],
          p = position;
      final d = (b.dy - c.dy) * (a.dx - c.dx) + (c.dx - b.dx) * (a.dy - c.dy);
      if (d.abs() < 1e-10) continue;
      final u =
          ((b.dy - c.dy) * (p.dx - c.dx) + (c.dx - b.dx) * (p.dy - c.dy)) / d;
      final v =
          ((c.dy - a.dy) * (p.dx - c.dx) + (a.dx - c.dx) * (p.dy - c.dy)) / d;
      final w = 1 - u - v;
      if (u >= -1e-6 && v >= -1e-6 && w >= -1e-6) {
        final anchor = FacePointAnchor(point, t, [u, v, w]);
        if (!profile) {
          best = anchor;
          break;
        }
        final depth =
            sign *
            (u * mesh.vertices[t[0]][0] +
                v * mesh.vertices[t[1]][0] +
                w * mesh.vertices[t[2]][0]);
        if (depth > outermost) {
          outermost = depth;
          best = anchor;
        }
      }
    }
    if (best != null) result.add(best);
  }
  return result;
}

/// Conservative face outline in the original 864 x 1152 illustration.
/// Blank paper around the jaw/ears must not receive projected markers.
bool isInsideFaceIllustration(Offset uv) {
  final outline = Path()
    ..addPolygon(const [
      Offset(230, 280),
      Offset(320, 255),
      Offset(520, 255),
      Offset(635, 290),
      Offset(710, 400),
      Offset(705, 555),
      Offset(690, 700),
      Offset(668, 810),
      Offset(600, 905),
      Offset(510, 975),
      Offset(440, 999),
      Offset(365, 975),
      Offset(275, 905),
      Offset(205, 810),
      Offset(174, 700),
      Offset(155, 555),
      Offset(155, 400),
    ], true);
  return outline.contains(Offset(uv.dx * 864, uv.dy * 1152));
}
