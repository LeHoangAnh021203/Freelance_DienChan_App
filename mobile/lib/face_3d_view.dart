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
    this.showGrid = true,
  });
  final List<FacePoint> markers;
  final String? highlightCode;
  final bool showLabels;
  final bool showGrid;
  final bool embedded;
  final VoidCallback? onShow2D;
  @override
  State<Face3DPage> createState() => _Face3DPageState();
}

class _Face3DPageState extends State<Face3DPage>
    with SingleTickerProviderStateMixin {
  late Future<FaceMesh> _mesh;
  late final AnimationController _pulse;
  double _yaw = 0, _pitch = 0, _zoom = 1, _startZoom = 1;
  final bool _wire = false;
  ui.Image? _drawing;
  int _loadGeneration = 0;
  List<double>? _focus;
  FaceMesh? _loadedMesh;

  @override
  void didUpdateWidget(covariant Face3DPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightCode != widget.highlightCode) {
      setState(_focusSelection);
    }
  }

  void _syncPulse() {
    if (widget.highlightCode == null) {
      _pulse
        ..stop()
        ..value = 0;
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat();
  }

  void _focusSelection() {
    final mesh = _loadedMesh;
    _focus = null;
    _syncPulse();
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
      final profile = anchor.point.projection != FacePointProjection.front;
      if (!profile && !isInsideFaceIllustration(uv)) continue;
      _focus = List.generate(
        3,
        (axis) => List.generate(
          3,
          (i) => mesh.vertices[anchor.triangle[i]][axis] * anchor.weights[i],
        ).reduce((a, b) => a + b),
      );
      if (anchor.point.projection.isBehindEar) {
        final sign =
            anchor.point.projection == FacePointProjection.behindLeftEar
            ? -1.0
            : 1.0;
        _yaw = (sign * 1.45).clamp(-1.48, 1.48);
        _zoom = 2.25;
      } else if (anchor.point.projection.isProfile) {
        final sign = anchor.point.projection == FacePointProjection.leftProfile
            ? -1.0
            : 1.0;
        _yaw = (sign * 1.2).clamp(-1.48, 1.48);
        _zoom = 2.15;
      } else {
        _yaw = (-math.atan2(_focus![0], _focus![2])).clamp(-1.1, 1.1);
        _zoom = 2.35;
      }
      _pitch = 0;
      break;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _loadGeneration++;
    _drawing?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _syncPulse();
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
      if (mounted && generation == _loadGeneration) {
        _focusSelection();
      }
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
    backgroundColor: widget.embedded ? Colors.transparent : null,
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
                              widget.showGrid,
                              _focus,
                              _pulse,
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
    this.showGrid,
    this.focus,
    this.pulse,
  ) : super(repaint: pulse);
  final Animation<double> pulse;
  final List<double>? focus;
  final List<FacePoint> markers;
  final String? highlightCode;
  final bool showLabels;
  final bool showGrid;
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
    final pendingLabels = <({Offset spot, double depth, String code, bool active})>[];
    final codes = markers.map((p) => p.code).toSet().toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    final colors = {
      for (var i = 0; i < codes.length; i++)
        codes[i]: i.isEven ? const Color(0xFFE53935) : const Color(0xFF3299C4),
    };
    final uvs = mesh.vertices.map(faceDrawingUV).toList();
    final gridPaint = Paint()
      ..color = const Color(0x997DB7CB)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = const Color(0x5CFFFFFF),
    );
    for (final t in triangles) {
      final a = points[t[0]], b = points[t[1]], c = points[t[2]];
      final pa = project(a), pb = project(b), pc = project(c);
      final path = Path()
        ..moveTo(pa.dx, pa.dy)
        ..lineTo(pb.dx, pb.dy)
        ..lineTo(pc.dx, pc.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFF7FBFF));
      if (texturePaint != null) {
        final vertices = ui.Vertices(
          ui.VertexMode.triangles,
          [pa, pb, pc],
          textureCoordinates: t.map(texturePoint).toList(),
        );
        canvas.drawVertices(vertices, BlendMode.srcOver, texturePaint);
        vertices.dispose();
      }
    }
    canvas.restore();

    if (showGrid) {
      for (final t in triangles) {
        _drawUvGrid(
          canvas,
          [project(points[t[0]]), project(points[t[1]]), project(points[t[2]])],
          [uvs[t[0]], uvs[t[1]], uvs[t[2]]],
          gridPaint,
        );
      }
      _drawGridLabels(canvas, uvs, points, project);
    }

    for (final t in triangles) {
      final a = points[t[0]], b = points[t[1]], c = points[t[2]];
      for (final anchor in anchors.where((a) => identical(a.triangle, t))) {
        final illustrationPosition = List.generate(
          3,
          (i) =>
              faceDrawingUV(mesh.vertices[anchor.triangle[i]]) *
              anchor.weights[i],
        ).reduce((a, b) => a + b);
        if (!shouldDrawFaceAnchor(anchor, illustrationPosition)) continue;
        final position = List<double>.generate(
          3,
          (axis) =>
              a[axis] * anchor.weights[0] +
              b[axis] * anchor.weights[1] +
              c[axis] * anchor.weights[2],
        );
        final spot = project(position);
        final active = anchor.point.code == highlightCode;
        if (active) {
          final wave = (math.sin(pulse.value * math.pi * 2) + 1) / 2;
          canvas.drawCircle(
            spot,
            18 + wave * 10,
            Paint()
              ..color = const Color(
                0xFFFF6D00,
              ).withValues(alpha: 0.16 * (1 - wave)),
          );
          canvas.drawCircle(
            spot,
            12 + wave * 8,
            Paint()
              ..color = const Color(
                0xFFFF8F00,
              ).withValues(alpha: 0.55 * (1 - wave))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.6,
          );
          canvas.drawCircle(
            spot,
            8 + wave * 3,
            Paint()
              ..color = const Color(
                0xFFFFC107,
              ).withValues(alpha: 0.28 + wave * 0.18),
          );
        }
        canvas.drawCircle(
          spot,
          active ? 7 : 3.5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          spot,
          active ? 4.8 : 2.5,
          Paint()
            ..color = active
                ? const Color(0xFFE53935)
                : colors[anchor.point.code]!.withValues(
                    alpha: highlightCode == null ? 1 : 0.18,
                  ),
        );
        // Labels follow the "Số" toggle only; selected points still pulse.
        if (showLabels) {
          // Skip labels on the far side of the mesh so numbers don't stack
          // through the head while rotating.
          if (active || position[2] > -0.35) {
            pendingLabels.add((
              spot: spot,
              depth: position[2],
              code: anchor.point.code,
              active: active,
            ));
          }
        }
      }
    }

    // Front-most labels first; short codes + collision so 3D stays readable.
    pendingLabels.sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      return b.depth.compareTo(a.depth);
    });
    for (final item in pendingLabels) {
      final label = TextPainter(
        text: TextSpan(
          text: item.active ? 'Huyệt ${item.code}' : item.code,
          style: TextStyle(
            fontSize: item.active ? 13 : 8.5,
            color: item.active ? const Color(0xFF7A1D1D) : const Color(0xFF1A2A32),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final offsets = <Offset>[
        Offset(item.spot.dx + (item.active ? 16 : 5), item.spot.dy - label.height / 2),
        Offset(item.spot.dx - label.width - (item.active ? 16 : 5), item.spot.dy - label.height / 2),
        Offset(item.spot.dx - label.width / 2, item.spot.dy - label.height - 10),
        Offset(item.spot.dx - label.width / 2, item.spot.dy + 8),
      ];
      Offset? chosenOrigin;
      Rect? chosenBounds;
      for (final origin in offsets) {
        final bounds = Rect.fromLTWH(
          origin.dx - 4,
          origin.dy - 2,
          label.width + 8,
          label.height + 4,
        ).inflate(item.active ? 0 : 2);
        if (item.active ||
            !occupiedLabels.any((rect) => rect.overlaps(bounds))) {
          chosenOrigin = origin;
          chosenBounds = bounds;
          break;
        }
      }
      if (chosenOrigin == null || chosenBounds == null) continue;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          chosenOrigin.dx - 4,
          chosenOrigin.dy - 2,
          label.width + 8,
          label.height + 4,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = item.active
              ? const Color(0xFFFFF6E0)
              : const Color(0xE6FFFFFF),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = item.active
              ? const Color(0xFFE8C56B)
              : const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      label.paint(canvas, chosenOrigin);
      occupiedLabels.add(chosenBounds);
    }
    canvas.restore();
  }

  void _drawUvGrid(
    Canvas canvas,
    List<Offset> screen,
    List<Offset> uv,
    Paint paint,
  ) {
    List<Offset> hits(double t, bool horizontal) {
      final found = <Offset>[];
      for (var i = 0; i < 3; i++) {
        final a = uv[i], b = uv[(i + 1) % 3];
        final av = horizontal ? a.dy : a.dx;
        final bv = horizontal ? b.dy : b.dx;
        final span = bv - av;
        if (span.abs() < 1e-9) continue;
        final f = (t - av) / span;
        if (f < -1e-6 || f > 1 + 1e-6) continue;
        found.add(Offset.lerp(screen[i], screen[(i + 1) % 3], f.clamp(0, 1))!);
      }
      return found;
    }

    for (var i = 1; i < 14; i++) {
      final line = hits(i / 14, false);
      if (line.length >= 2) canvas.drawLine(line[0], line[1], paint);
    }
    for (var i = 1; i < 16; i++) {
      final line = hits(i / 16, true);
      if (line.length >= 2) canvas.drawLine(line[0], line[1], paint);
    }
  }

  void _drawGridLabels(
    Canvas canvas,
    List<Offset> uvs,
    List<List<double>> rotated,
    Offset Function(List<double>) project,
  ) {
    Offset? projectUv(Offset uv) {
      for (final t in mesh.triangles) {
        final a = uvs[t[0]], b = uvs[t[1]], c = uvs[t[2]];
        final d = (b.dy - c.dy) * (a.dx - c.dx) + (c.dx - b.dx) * (a.dy - c.dy);
        if (d.abs() < 1e-10) continue;
        final u =
            ((b.dy - c.dy) * (uv.dx - c.dx) + (c.dx - b.dx) * (uv.dy - c.dy)) /
            d;
        final v =
            ((c.dy - a.dy) * (uv.dx - c.dx) + (a.dx - c.dx) * (uv.dy - c.dy)) /
            d;
        final w = 1 - u - v;
        if (u < -1e-4 || v < -1e-4 || w < -1e-4) continue;
        return project([
          rotated[t[0]][0] * u + rotated[t[1]][0] * v + rotated[t[2]][0] * w,
          rotated[t[0]][1] * u + rotated[t[1]][1] * v + rotated[t[2]][1] * w,
          rotated[t[0]][2] * u + rotated[t[1]][2] * v + rotated[t[2]][2] * w,
        ]);
      }
      return null;
    }

    const style = TextStyle(
      color: Color(0xD9A65B38),
      fontSize: 8,
      fontWeight: FontWeight.w700,
    );
    const hLabels = [
      'L',
      'K',
      'H',
      'G',
      'E',
      'D',
      'C',
      'B',
      'A',
      '0',
      'A',
      'B',
      'C',
      'D',
      'E',
      'G',
      'H',
      'K',
      'L',
    ];
    const vLabels = [
      'O',
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];
    for (var i = 0; i < hLabels.length; i++) {
      final at = projectUv(Offset((i + 0.5) / hLabels.length, 0.97));
      if (at == null) continue;
      final tp = TextPainter(
        text: TextSpan(text: hLabels[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(at.dx - tp.width / 2, at.dy));
    }
    for (var i = 0; i < vLabels.length; i++) {
      final at = projectUv(Offset(0.96, (i + 0.7) / (vLabels.length + 1)));
      if (at == null) continue;
      final tp = TextPainter(
        text: TextSpan(text: vLabels[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(at.dx + 2, at.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FaceMeshPainter old) =>
      old.focus != focus ||
      old.markers != markers ||
      old.highlightCode != highlightCode ||
      old.showLabels != showLabels ||
      old.showGrid != showGrid ||
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

enum FacePointProjection {
  front,
  rightProfile,
  leftProfile,
  behindRightEar,
  behindLeftEar,
}

extension FacePointProjectionX on FacePointProjection {
  bool get isProfile =>
      this == FacePointProjection.rightProfile ||
      this == FacePointProjection.leftProfile;
  bool get isBehindEar =>
      this == FacePointProjection.behindRightEar ||
      this == FacePointProjection.behindLeftEar;
}

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
    if (point.projection.isBehindEar) {
      final anchor = _anchorBehindEar(mesh, point);
      if (anchor != null) result.add(anchor);
      continue;
    }
    final profile = point.projection.isProfile;
    final coordinates = profile
        ? mesh.vertices.map((v) => Offset(v[2], v[1])).toList()
        : uv;
    final position = profile
        ? profilePhotoToPlane(point.position)
        : point.position;
    FacePointAnchor? best;
    var outermost = -double.infinity;
    final sign = point.projection == FacePointProjection.leftProfile ? -1 : 1;
    for (final t in mesh.triangles) {
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
    if (best == null && profile && position.dx.abs() < 80) {
      var nearest = -1;
      var nearestDist = double.infinity;
      for (var i = 0; i < mesh.vertices.length; i++) {
        final v = mesh.vertices[i];
        if (v[0] * sign < -1e-6) continue;
        final dz = v[2] - position.dx;
        final dy = v[1] - position.dy;
        final dist = dz * dz + dy * dy;
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = i;
        }
      }
      if (nearest >= 0) {
        for (final t in mesh.triangles) {
          if (!t.contains(nearest)) continue;
          if (t.any((i) => mesh.vertices[i][0] * sign < -1e-6)) continue;
          best = FacePointAnchor(point, t, [
            t[0] == nearest ? 1.0 : 0.0,
            t[1] == nearest ? 1.0 : 0.0,
            t[2] == nearest ? 1.0 : 0.0,
          ]);
          break;
        }
      }
    }
    if (best != null) result.add(best);
  }
  return result;
}

FacePointAnchor? _anchorBehindEar(FaceMesh mesh, FacePoint point) {
  final sign = point.projection == FacePointProjection.behindLeftEar ? -1 : 1;
  // Skin just anterior to the ear, not the mesh rim that floats off the cheek.
  final target = [sign * 5.35, 2.05, 2.9];
  FacePointAnchor? best;
  var bestDist = double.infinity;
  for (final t in mesh.triangles) {
    if (t.any((i) => mesh.vertices[i][0] * sign < -1e-6)) continue;
    final a = mesh.vertices[t[0]],
        b = mesh.vertices[t[1]],
        c = mesh.vertices[t[2]];
    final bary = closestPointOnTriangle(target, a, b, c);
    final px = a[0] * bary[0] + b[0] * bary[1] + c[0] * bary[2];
    final py = a[1] * bary[0] + b[1] * bary[1] + c[1] * bary[2];
    final pz = a[2] * bary[0] + b[2] * bary[1] + c[2] * bary[2];
    final dx = px - target[0], dy = py - target[1], dz = pz - target[2];
    final dist = dx * dx + dy * dy + dz * dz;
    if (dist < bestDist) {
      bestDist = dist;
      best = FacePointAnchor(point, t, bary);
    }
  }
  return best;
}

/// Clamp a 3D point onto triangle ABC so markers stay on the surface.
List<double> closestPointOnTriangle(
  List<double> p,
  List<double> a,
  List<double> b,
  List<double> c,
) {
  List<double> sub(List<double> u, List<double> v) => [
    u[0] - v[0],
    u[1] - v[1],
    u[2] - v[2],
  ];
  double dot(List<double> u, List<double> v) =>
      u[0] * v[0] + u[1] * v[1] + u[2] * v[2];
  final ab = sub(b, a), ac = sub(c, a), ap = sub(p, a);
  final d1 = dot(ab, ap), d2 = dot(ac, ap);
  if (d1 <= 0 && d2 <= 0) return [1, 0, 0];
  final bp = sub(p, b);
  final d3 = dot(ab, bp), d4 = dot(ac, bp);
  if (d3 >= 0 && d4 <= d3) return [0, 1, 0];
  final vc = d1 * d4 - d3 * d2;
  if (vc <= 0 && d1 >= 0 && d3 <= 0) {
    final v = d1 / (d1 - d3);
    return [1 - v, v, 0];
  }
  final cp = sub(p, c);
  final d5 = dot(ab, cp), d6 = dot(ac, cp);
  if (d6 >= 0 && d5 <= d6) return [0, 0, 1];
  final vb = d5 * d2 - d1 * d6;
  if (vb <= 0 && d2 >= 0 && d6 <= 0) {
    final w = d2 / (d2 - d6);
    return [1 - w, 0, w];
  }
  final va = d3 * d6 - d5 * d4;
  if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
    final w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
    return [0, 1 - w, w];
  }
  final denom = 1 / (va + vb + vc);
  final v = vb * denom, w = vc * denom;
  return [1 - v - w, v, w];
}

/// Front dots stay inside the drawn face. Profile-only dots sit on the
/// cheek/jaw, so the frontal paper mask would hide them.
bool shouldDrawFaceAnchor(FacePointAnchor anchor, Offset illustrationUv) {
  if (anchor.point.projection != FacePointProjection.front) return true;
  return isInsideFaceIllustration(illustrationUv);
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
