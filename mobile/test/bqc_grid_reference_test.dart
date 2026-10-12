import 'package:dien_chan_app/bqc_grid_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Expanded source includes both table pages and diagram-only records',
    () {
      expect(bqcGridReferences.length, 259);
      for (final code in [
        '5',
        '179',
        '185',
        '188',
        '437',
        '567',
        '630',
        '631',
        '632',
        '633',
        '4',
      ]) {
        expect(bqcGridReferences.containsKey(code), isTrue, reason: code);
      }
      expect(bqcGridReferences['179']!.column, 'C-D');
      expect(bqcGridReferences['179']!.row, '4-5');
      expect(bqcGridReferences['633']!.page, 153);
      for (final code in ['281', '46', '437']) {
        expect(
          bqcFrontPositions(code),
          isEmpty,
          reason: 'Do not invent coordinates for $code',
        );
      }
      expect(bqcGridReferences['531']!.regions.first.width, greaterThan(0));
    },
  );
  test(
    'Source grid corrects forehead codes and excludes profile-only points',
    () {
      expect(bqcGridReferences['26']!.row, '4');
      expect(bqcGridReferences['124']!.column, 'H');
      expect(bqcGridReferences['124']!.row, '2');
      expect(bqcFrontPositions('0'), isEmpty);
      expect(bqcFrontPositions('55'), isEmpty);
      expect(bqcFrontPositions('unknown'), isEmpty);
      expect(bqcGridReferences['62']!.note, isNotEmpty);
    },
  );
  test(
    'Bilateral positions mirror while midline and sided points stay single',
    () {
      final pair = bqcFrontPositions('73');
      expect(pair, hasLength(2));
      expect(pair.first.dx + pair.last.dx, closeTo(1, 1e-10));
      expect(pair.first.dy, pair.last.dy);
      expect(bqcFrontPositions('87'), hasLength(1));
      expect(bqcFrontPositions('87').single.dx, 0.5);
      expect(bqcFrontPositions('41').single.dx, lessThan(0.5));
      expect(bqcFrontPositions('37').single.dx, greaterThan(0.5));
    },
  );
  test(
    'Source intervals remain regions and all mapped coordinates are bounded',
    () {
      final region = bqcGridReferences['467']!.regions.first;
      expect(region.width, greaterThan(0));
      expect(region.height, greaterThan(0));
      expect(const BqcGridReference('O', '99').regions, isEmpty);
      for (final reference in bqcGridReferences.values) {
        for (final region in reference.regions) {
          expect(region.left, inInclusiveRange(0, 1));
          expect(region.right, inInclusiveRange(region.left, 1));
          expect(region.top, inInclusiveRange(0, 1));
          expect(region.bottom, inInclusiveRange(region.top, 1));
        }
      }
    },
  );
}
