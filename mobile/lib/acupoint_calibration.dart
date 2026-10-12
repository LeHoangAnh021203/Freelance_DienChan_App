import 'package:flutter/material.dart';

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

Rect fittedFrontDiagram(Size size) {
  final fitted = applyBoxFit(BoxFit.contain, const Size(864, 1152), size);
  return Alignment.center.inscribe(fitted.destination, Offset.zero & size);
}
