import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/features/startup/olivos_mark.dart';

void main() {
  test('动画按 2/4、1/3、5-9 的顺序分组', () {
    final lines = {for (final line in olivosMarkLines) line.id: line};

    expect(lines[2]!.start, 0);
    expect(lines[4]!.start, 0);
    expect(lines[4]!.start + lines[4]!.duration, lessThanOrEqualTo(0.17));
    expect(lines[1]!.start, 0.17);
    expect(lines[3]!.start, 0.17);
    expect(lines[1]!.start + lines[1]!.duration, lessThanOrEqualTo(0.48));
    expect(lines[1]!.reverse, isFalse);
    expect(lines[3]!.reverse, isTrue);
    expect(lines[4]!.reverse, isFalse);

    // 5-8 start together after 3; 9 follows immediately after 8.
    expect(
      lines[5]!.start,
      greaterThanOrEqualTo(lines[3]!.start + lines[3]!.duration),
    );
    expect(lines[5]!.start, lessThan(lines[1]!.start + lines[1]!.duration));
    expect(lines[5]!.start, 0.34);
    expect(lines[6]!.start, 0.34);
    expect(lines[7]!.start, 0.34);
    expect(lines[8]!.start, 0.34);
    expect(
      lines[9]!.start,
      closeTo(lines[8]!.start + lines[8]!.duration, 1e-9),
    );
    expect(lines[5]!.reverse, isTrue);
    expect(lines[6]!.reverse, isFalse);
    expect(lines[7]!.reverse, isFalse);
    expect(lines[8]!.reverse, isFalse);
    expect(lines[9]!.reverse, isFalse);
  });

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
