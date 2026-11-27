import 'dart:ui';

/// The brand blue used by the OlivOS icon.
const Color olivosBrandBlue = Color(0xFF00A0EA);

/// Bounds of the OlivOS mark inside the original logo vector.
const Rect olivosMarkBounds = Rect.fromLTRB(16.79, 0, 122.86, 96.3);

/// One visually distinct line of the mark.
///
/// A line can contain multiple source polygons (for example, a long diagonal
/// stripe is split into two polygons). They are animated together so a line is
/// only drawn once.
class OlivOSMarkLine {
  const OlivOSMarkLine({
    required this.id,
    required this.start,
    required this.duration,
    required this.polygons,
    this.reverse = false,
    this.extendStart = false,
    this.extendEnd = false,
  });

  /// Unique id. Duplicate ids are ignored by the painter.
  ///
  /// The default IDs match the numbered reference image: 1 and 2 are the two
  /// long lower diagonals, 3 is the upper-right ring side, 4 is the outer
  /// upper-right diagonal, 5 is the top bar, 6-8 continue counter-clockwise,
  /// and 9 is the right horizontal bar.
  final int id;

  /// Normalized position and duration inside the mark drawing phase.
  ///
  /// Lines with the same [start] begin together. This allows the long 1/2
  /// diagonals to take noticeably longer than the remaining construction.
  final double start;
  final double duration;

  /// Source polygons in the icon's original vector coordinate space.
  final List<List<Offset>> polygons;

  /// Draw from the line's end toward its start.
  ///
  /// The start is the end closer to the top/left; the end is closer to the
  /// bottom/right. Reversing changes the visual growth direction without
  /// moving the line.
  final bool reverse;

  /// Translate the start/end cap outward along the line's long axis.
  ///
  /// The cap itself is moved without changing its cut angle. Extended lines are
  /// clipped by the screen, so they keep going beyond its edge.
  final bool extendStart;
  final bool extendEnd;
}

/// The numbered OlivOS mark, in the requested construction order.
///
/// Pass a custom list to [LaunchGate.lines] to change timing, growth direction,
/// or which lines extend beyond the screen. Lines with the same [start] animate
/// simultaneously. Duplicate [id]s are drawn once.
const List<OlivOSMarkLine> olivosMarkLines = [
  // 1: lower-left long diagonal. Draw from lower-left toward upper-right.
  OlivOSMarkLine(
    id: 1,
    start: 0,
    duration: 0.30,
    reverse: true,
    extendEnd: true,
    polygons: [
      [
        Offset(96.56, 51.53),
        Offset(82.17, 76.12),
        Offset(71.68, 76.28),
        Offset(91.5, 42.38),
      ],
      [
        Offset(82.7, 75.22),
        Offset(82.18, 76.11),
        Offset(70.37, 96.3),
        Offset(59.95, 96.3),
        Offset(71.68, 76.28),
        Offset(77.64, 66.1),
      ],
    ],
  ),
  // 2: adjacent lower diagonal. Draw from lower-left toward upper-right.
  OlivOSMarkLine(
    id: 2,
    start: 0,
    duration: 0.30,
    reverse: true,
    extendEnd: true,
    polygons: [
      [
        Offset(112.45, 51.48),
        Offset(98.06, 76.07),
        Offset(87.56, 76.23),
        Offset(107.39, 42.33),
      ],
      [
        Offset(98.58, 75.18),
        Offset(98.06, 76.07),
        Offset(86.23, 96.3),
        Offset(75.84, 96.3),
        Offset(87.57, 76.23),
        Offset(93.54, 66.04),
      ],
    ],
  ),
  // 3: upper-right ring side. Draw from lower-right toward upper-left.
  OlivOSMarkLine(
    id: 3,
    start: 0.31,
    duration: 0.16,
    reverse: true,
    polygons: [
      [
        Offset(88.95, 13.35),
        Offset(104.08, 37.5),
        Offset(99.36, 46.87),
        Offset(78.51, 13.59),
      ],
    ],
  ),
  // 4: outer upper-right diagonal. Draw from lower-left toward upper-right.
  // The top cap is horizontal; it is moved as a whole along the line axis so
  // its cut angle never changes.
  OlivOSMarkLine(
    id: 4,
    start: 0.31,
    duration: 0.16,
    reverse: true,
    extendStart: true,
    polygons: [
      [
        Offset(122.86, 0),
        Offset(122.86, 6.04),
        Offset(120.48, 10.15),
        Offset(106.7, 33.9),
        Offset(101.61, 24.77),
        Offset(115.39, 1.03),
        Offset(115.91, 0.13),
      ],
    ],
  ),
  // 5: top bar. Draw from right toward left.
  OlivOSMarkLine(
    id: 5,
    start: 0.48,
    duration: 0.09,
    reverse: true,
    polygons: [
      [
        Offset(53.03, 0.96),
        Offset(81.52, 0.96),
        Offset(86.96, 9.94),
        Offset(47.69, 9.94),
      ],
    ],
  ),
  // 6: upper-left diagonal. Draw from upper-right toward lower-left.
  OlivOSMarkLine(
    id: 6,
    start: 0.58,
    duration: 0.09,
    polygons: [
      [
        Offset(24.36, 25.36),
        Offset(38.99, 0.9),
        Offset(49.48, 0.85),
        Offset(29.33, 34.55),
      ],
    ],
  ),
  // 7: lower-left diagonal. Draw from upper-left toward lower-right.
  OlivOSMarkLine(
    id: 7,
    start: 0.68,
    duration: 0.09,
    polygons: [
      [
        Offset(31.34, 62.55),
        Offset(16.79, 38.05),
        Offset(21.74, 28.79),
        Offset(41.78, 62.56),
      ],
    ],
  ),
  // 8: bottom bar. Draw from left toward right.
  OlivOSMarkLine(
    id: 8,
    start: 0.78,
    duration: 0.09,
    polygons: [
      [
        Offset(67.71, 75.09),
        Offset(39.22, 75.09),
        Offset(33.78, 66.11),
        Offset(73.05, 66.11),
      ],
    ],
  ),
  // 9: right horizontal bar. Draw from left toward right.
  OlivOSMarkLine(
    id: 9,
    start: 0.88,
    duration: 0.09,
    extendEnd: true,
    polygons: [
      [
        Offset(122.86, 66.11),
        Offset(122.86, 75.09),
        Offset(103.03, 75.09),
        Offset(108.38, 66.11),
      ],
    ],
  ),
];
