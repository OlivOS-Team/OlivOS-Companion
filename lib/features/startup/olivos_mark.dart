import 'dart:ui';

/// The brand blue used by the OlivOS icon.
const Color olivosBrandBlue = Color(0xFF00A0EA);

/// Bounds of the OlivOS mark inside the original logo vector.
const Rect olivosMarkBounds = Rect.fromLTRB(16.79, 0, 122.86, 96.3);

/// One visually distinct line of the mark.
///
/// A line can contain multiple source polygons for shapes that were split in
/// the source vector. The built-in mark uses one merged polygon per line; they
/// are still animated together so a line is only drawn once.
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
/// Coordinates are snapped to the icon's 0/60/90/120-degree construction axes
/// so adjacent stripes share exactly parallel edges.
///
/// Pass a custom list to [LaunchGate.lines] to change timing, growth direction,
/// or which lines extend beyond the screen. Lines with the same [start] animate
/// simultaneously. Duplicate [id]s are drawn once.
const List<OlivOSMarkLine> olivosMarkLines = [
  // First group: 2 and 4. Once 4 finishes, 1 and 3 start together; 2 can still
  // be finishing. After 3 finishes, 5-8 start in order with a 0.02 stagger;
  // 9 follows as soon as 8 completes.
  // 1: lower-left long diagonal. Draw from upper-right toward lower-left.
  // The two source segments are merged into one polygon; the bottom cap still
  // gets the off-screen extension.
  OlivOSMarkLine(
    id: 1,
    start: 0.21,
    duration: 0.30,
    extendEnd: true,
    polygons: [
      [
        Offset(96.4834, 51.3801),
        Offset(91.2723, 42.3542),
        Offset(71.6839, 76.2823),
        Offset(60.0822, 96.3770),
        Offset(70.5044, 96.3770),
        Offset(82.1992, 76.1211),
        Offset(82.7146, 75.2284),
      ],
    ],
  ),
  // 2: adjacent lower diagonal. Draw from lower-left toward upper-right.
  // Like 1, its source segments are merged into one polygon.
  OlivOSMarkLine(
    id: 2,
    start: 0,
    duration: 0.30,
    reverse: true,
    extendEnd: true,
    polygons: [
      [
        Offset(112.3765, 51.3307),
        Offset(107.1674, 42.3083),
        Offset(87.5771, 76.2399),
        Offset(75.9530, 96.3733),
        Offset(86.3711, 96.3733),
        Offset(98.0849, 76.0844),
      ],
    ],
  ),
  // 3: upper-right ring side. Draw from lower-right toward upper-left.
  OlivOSMarkLine(
    id: 3,
    start: 0.21,
    duration: 0.20,
    reverse: true,
    polygons: [
      [
        Offset(89.4879, 13.1644),
        Offset(103.8051, 37.9624),
        Offset(98.5764, 47.0187),
        Offset(79.0306, 13.1644),
      ],
    ],
  ),
  // 4: outer upper-right diagonal. Draw from upper-right toward lower-left.
  // The top cap is horizontal; it is moved as a whole along the line axis so
  // its cut angle never changes.
  OlivOSMarkLine(
    id: 4,
    start: 0,
    duration: 0.20,
    extendStart: true,
    polygons: [
      [
        Offset(122.8551, 0.0609),
        Offset(122.8551, 6.0343),
        Offset(120.4792, 10.1495),
        Offset(106.7896, 33.8606),
        Offset(101.5856, 24.8470),
        Offset(115.3497, 1.0067),
        Offset(115.8958, 0.0609),
      ],
    ],
  ),
  // 5: top bar. Draw from right toward left.
  OlivOSMarkLine(
    id: 5,
    start: 0.42,
    duration: 0.10,
    reverse: true,
    polygons: [
      [
        Offset(52.9780, 0.9155),
        Offset(81.6220, 0.9155),
        Offset(86.8580, 9.9845),
        Offset(47.7420, 9.9845),
      ],
    ],
  ),
  // 6: upper-left diagonal. Draw from upper-right toward lower-left.
  OlivOSMarkLine(
    id: 6,
    start: 0.44,
    duration: 0.10,
    polygons: [
      [
        Offset(24.4535, 25.5528),
        Offset(38.7763, 0.7450),
        Offset(49.2432, 0.7450),
        Offset(29.6870, 34.6173),
      ],
    ],
  ),
  // 7: lower-left diagonal. Draw from upper-left toward lower-right.
  OlivOSMarkLine(
    id: 7,
    start: 0.46,
    duration: 0.10,
    polygons: [
      [
        Offset(31.1487, 62.6576),
        Offset(16.8259, 37.8498),
        Offset(22.0595, 28.7850),
        Offset(41.6159, 62.6576),
      ],
    ],
  ),
  // 8: bottom bar. Draw from left toward right.
  OlivOSMarkLine(
    id: 8,
    start: 0.48,
    duration: 0.10,
    polygons: [
      [
        Offset(67.7620, 75.1345),
        Offset(39.1180, 75.1345),
        Offset(33.8820, 66.0655),
        Offset(72.9980, 66.0655),
      ],
    ],
  ),
  // 9: right horizontal bar. Draw from left toward right.
  OlivOSMarkLine(
    id: 9,
    start: 0.58,
    duration: 0.10,
    extendEnd: true,
    polygons: [
      [
        Offset(122.8600, 66.0895),
        Offset(122.8600, 75.1105),
        Offset(103.1009, 75.1105),
        Offset(108.3091, 66.0895),
      ],
    ],
  ),
];
