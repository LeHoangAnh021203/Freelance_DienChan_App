import 'package:flutter/material.dart';

import 'bqc_digitized.dart';
import 'bqc_grid_reference.dart';

const bqcLandmarkSource =
    'https://dienchan.com/cap-nhat-bo-huyet-moc-bqc-va-do-hinh-bo-huyet-bqc-dien-chan-dieu-khien-lieu-phap';

/// Anatomical descriptions from the source; pixel positions are manually
/// aligned to OUR 864x1152 illustration, not coordinates published by BQC.
/// No clinical validation or individual-face calibration is implied.
class AcupointCalibration {
  const AcupointCalibration(this.pixel, this.location);
  final Offset pixel;
  final String location;
  Offset get normalized => Offset(pixel.dx / 864, pixel.dy / 1152);
}

const acupointCalibrations = <String, AcupointCalibration>{
  '8': AcupointCalibration(Offset(432, 500), 'Sống mũi, ngang mắt'),
  '19': AcupointCalibration(Offset(432, 716), 'Đầu trên rãnh nhân trung'),
  '26': AcupointCalibration(Offset(432, 445), 'Giữa hai lông mày'),
  '63': AcupointCalibration(Offset(432, 745), 'Giữa rãnh nhân trung'),
  '87': AcupointCalibration(Offset(432, 941), 'Phần nhô nhất của ụ cằm'),
  '103': AcupointCalibration(Offset(432, 350), 'Trung tâm trán'),
  '106': AcupointCalibration(Offset(432, 402), 'Giữa vùng trán thấp'),
  '127': AcupointCalibration(Offset(432, 885), 'Phần trên ụ cằm, gần môi dưới'),
};

const _colRank = <String, int>{
  'O': 0,
  'A': 1,
  'B': 2,
  'C': 3,
  'D': 4,
  'E': 5,
  'G': 6,
  'H': 7,
  'K': 8,
  'L': 9,
  'M': 10,
  'N': 11,
  'P': 12,
  'Q': 13,
  'R': 14,
};

/// Short Vietnamese landmark so nearby codes are easier to tell apart.
String acupointLocationLabel(String code) {
  final named = acupointCalibrations[code]?.location;
  if (named != null && named.isNotEmpty) return named;

  final ref = bqcGridReferences[code];
  if (ref == null) return 'Huyệt $code trên gương mặt';
  if (ref.row == 'Sau tai') return 'Sau tai';

  final horizontal = _horizontalBand(ref.column, ref.side);
  final vertical = _verticalBand(ref.row);
  final parts = <String>[
    if (horizontal != null) _capitalize(horizontal),
    if (vertical != null &&
        (horizontal == null || !horizontal.contains(vertical)))
      vertical,
  ];
  if (parts.isEmpty) return 'Huyệt $code trên gương mặt';
  return parts.join(', ');
}

/// Extra sentence when the 3D view has to yaw away from the front.
String? acupointViewHint(String code) {
  if (isBehindEarAcupoint(code)) {
    return 'Mặt 3D đã xoay để nhìn vùng tai.';
  }
  if (bqcFrontPositions(code).isEmpty && bqcSideSourceDots.containsKey(code)) {
    return 'Mặt 3D đã xoay sang mặt bên (trắc diện).';
  }
  return null;
}

String? _horizontalBand(String column, String side) {
  final letters = column
      .split('-')
      .map((part) => part.trim())
      .where(_colRank.containsKey)
      .toList();
  if (letters.isEmpty) return _namedColumn(column);

  letters.sort((a, b) => (_colRank[b] ?? 0).compareTo(_colRank[a] ?? 0));
  final outer = letters.first;
  final laterality = side == 'left'
      ? ' trái'
      : side == 'right'
      ? ' phải'
      : '';
  return switch (outer) {
    'O' => 'đường giữa mặt',
    'A' || 'B' => 'sát đường giữa$laterality',
    'C' || 'D' || 'E' => 'gò má trong$laterality',
    'G' || 'H' => 'má$laterality',
    'K' || 'L' => 'thái dương$laterality',
    _ => 'mặt bên (trắc diện)',
  };
}

String? _namedColumn(String column) {
  final value = column.trim();
  if (value.isEmpty || value == '-') return null;
  if (value == 'Dưới mũi') return 'dưới mũi';
  if (value == 'Giữa') return 'đường giữa mặt';
  if (value.startsWith('Trước')) return 'mặt bên, trước huyệt kề';
  if (value.contains('trắc diện')) return 'mặt bên (trắc diện)';
  if (value.startsWith('Chấm')) return 'có trên sơ đồ';
  if (value.startsWith('Chưa')) return 'chưa gắn lưới';
  return value.toLowerCase();
}

String? _verticalBand(String row) {
  if (row == 'Sau tai') return 'sau tai';
  if (row.isEmpty || row == '-' || row == 'Chưa rõ') return null;
  final nums = [
    for (final match in RegExp(r'\d+').allMatches(row))
      int.parse(match.group(0)!),
  ]..sort();
  if (nums.isEmpty) return null;
  if (nums.last - nums.first >= 10) return 'từ trán đến cằm';
  return switch (nums.first) {
    <= 1 => 'trán trên',
    <= 3 => 'trán',
    4 => 'ngang lông mày',
    5 => 'ngang mắt',
    6 => 'ngang sống mũi',
    7 => 'ngang mũi',
    8 => 'dưới mũi',
    9 => 'môi trên',
    10 => 'ngang miệng',
    11 => 'môi dưới',
    _ => 'cằm',
  };
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

Rect fittedFrontDiagram(Size size) {
  final fitted = applyBoxFit(BoxFit.contain, const Size(864, 1152), size);
  return Alignment.center.inscribe(fitted.destination, Offset.zero & size);
}
