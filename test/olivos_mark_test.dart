import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/features/startup/olivos_mark.dart';

void main() {
  test('默认图标的所有边都落在 0/60/90/120 度构造轴上', () {
    const canonicalAngles = [0.0, 60.0, 90.0, 120.0];

    for (final line in olivosMarkLines) {
      for (final polygon in line.polygons) {
        for (var index = 0; index < polygon.length; index++) {
          final start = polygon[index];
          final end = polygon[(index + 1) % polygon.length];
          final angle =
              math.atan2(end.dy - start.dy, end.dx - start.dx) *
              180 /
              math.pi %
              180;
          final difference = canonicalAngles
              .map(
                (canonical) => math.min(
                  (angle - canonical).abs(),
                  180 - (angle - canonical).abs(),
                ),
              )
              .reduce(math.min);

          expect(
            difference,
            lessThan(0.01),
            reason:
                'line ${line.id} edge $index has angle $angle, '
                'which is not parallel to a construction axis',
          );
        }
      }
    }
  });
}
