import 'package:flutter/material.dart';
import 'bqc_digitized.dart';

/// Exact photo-space observations, independent of the illustrative 3D warp.
class BqcSourceView extends StatelessWidget {
  const BqcSourceView({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final views = [
      if (bqcFrontSourceDots.containsKey(code))
        (
          'Chính diện · tr.154',
          'assets/references/bqc-front-154.jpg',
          bqcFrontSourceDots[code]!,
        ),
      if (bqcSideSourceDots.containsKey(code))
        (
          'Trắc diện · tr.155',
          'assets/references/bqc-side-155.jpg',
          bqcSideSourceDots[code]!,
        ),
    ];
    return DefaultTabController(
      length: views.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đối chiếu huyệt $code'),
          bottom: views.isEmpty
              ? null
              : TabBar(tabs: [for (final v in views) Tab(text: v.$1)]),
        ),
        body: views.isEmpty
            ? const Center(
                child: Text('Chưa đọc được chấm tương ứng trong ảnh nguồn.'),
              )
            : TabBarView(
                children: [
                  for (final v in views)
                    InteractiveViewer(
                      minScale: 1,
                      maxScale: 8,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(v.$2, fit: BoxFit.contain),
                                ),
                                Positioned(
                                  left: v.$3.dx * constraints.maxWidth - 7,
                                  top: v.$3.dy * constraints.maxHeight - 7,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
