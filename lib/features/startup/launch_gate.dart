import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'olivos_mark.dart';

// Timeline for the default 1420 ms animation. Line start/duration values are
// relative; the whole drawing schedule is scaled so its last line ends at
// 1000 ms, exactly when the pulse begins:
// - 0–1000 ms: line drawing
// - 1000–1252 ms: pulse
// - 1042–1420 ms: app fade-in
// - 1210–1420 ms: splash fade-out
const int _totalTimelineMs = 1420;
const int _lineEndTimelineMs = 1000;
const double _pulseStartFraction = 1000 / _totalTimelineMs;
const double _pulseEndFraction = 1252 / _totalTimelineMs;
const double _appFadeStartFraction = 1042 / _totalTimelineMs;
const double _splashFadeStartFraction = 1210 / _totalTimelineMs;

/// Plays the OlivOS mark construction animation before revealing [child].
class LaunchGate extends StatefulWidget {
  const LaunchGate({
    super.key,
    required this.child,
    this.lines = olivosMarkLines,
    this.duration = const Duration(milliseconds: _totalTimelineMs),
    this.onFinished,
  });

  final Widget child;

  /// Line definitions; their start/duration control the animation order.
  final List<OlivOSMarkLine> lines;

  final Duration duration;

  /// Called once after the animation has finished and the child is visible.
  final VoidCallback? onFinished;

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _appOpacity;
  late final Animation<double> _splashOpacity;
  bool _started = false;
  bool _finished = false;
  bool _finishNotified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _appOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _appFadeStartFraction,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    _splashOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          _splashFadeStartFraction,
          1,
          curve: Curves.easeInCubic,
        ),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _finished = true);
        _notifyFinished();
      }
    });
  }

  void _notifyFinished() {
    if (_finishNotified) return;
    _finishNotified = true;
    if (widget.onFinished == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFinished?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _finished = true;
      _notifyFinished();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(opacity: _appOpacity, child: widget.child),
        FadeTransition(
          opacity: _splashOpacity,
          child: AbsorbPointer(
            child: _LaunchSplash(animation: _controller, lines: widget.lines),
          ),
        ),
      ],
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash({required this.animation, required this.lines});

  final Animation<double> animation;
  final List<OlivOSMarkLine> lines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).startupAnimationLabel,
      container: true,
      child: ColoredBox(
        key: const Key('launch-splash'),
        color: olivosBrandBlue,
        child: CustomPaint(
          painter: _OlivOSMarkPainter(animation, lines),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _OlivOSMarkPainter extends CustomPainter {
  _OlivOSMarkPainter(this.animation, this.lines) : super(repaint: animation);

  final Animation<double> animation;
  final List<OlivOSMarkLine> lines;

  static final Paint _paint = Paint()
    ..color = Colors.white
    ..isAntiAlias = true;

  List<_LineGeometry>? _geometries;
  Rect? _geometriesRect;

  @override
  void paint(Canvas canvas, Size size) {
    final value = animation.value.clamp(0.0, 1.0);
    final lastLineEnd = lines.fold<double>(
      0,
      (latest, line) => math.max(latest, line.start + line.duration),
    );
    final drawProgress = lastLineEnd <= 0
        ? 1.0
        : (value * _totalTimelineMs * lastLineEnd / _lineEndTimelineMs).clamp(
            0.0,
            1.0,
          );
    final scale = _scaleAt(value);
    final aspect = olivosMarkBounds.width / olivosMarkBounds.height;
    final targetWidth = math.min(
      size.width * 0.62,
      size.height * 0.62 * aspect,
    );
    final fit = targetWidth / olivosMarkBounds.width;
    final effectiveScale = fit * scale;
    final center = olivosMarkBounds.center;
    final visibleRect = Rect.fromCenter(
      center: center,
      width: size.width / effectiveScale,
      height: size.height / effectiveScale,
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(effectiveScale);
    canvas.translate(-center.dx, -center.dy);

    final geometries = _geometriesFor(visibleRect);
    final seenIds = <int>{};
    for (final line in geometries) {
      if (!seenIds.add(line.id)) continue;
      final progress = ((drawProgress - line.startAt) / line.duration).clamp(
        0.0,
        1.0,
      );
      if (progress <= 0) continue;
      line.paint(
        canvas,
        Curves.easeInOutCubic.transform(progress),
        visibleRect,
      );
    }

    canvas.restore();
  }

  List<_LineGeometry> _geometriesFor(Rect visibleRect) {
    if (_geometriesRect == visibleRect && _geometries != null) {
      return _geometries!;
    }
    _geometriesRect = visibleRect;
    _geometries = [
      for (final line in lines) _LineGeometry.fromLine(line, visibleRect),
    ];
    return _geometries!;
  }

  double _scaleAt(double value) {
    if (value < _pulseStartFraction || value > _pulseEndFraction) return 1;
    final progress =
        ((value - _pulseStartFraction) /
                (_pulseEndFraction - _pulseStartFraction))
            .clamp(0.0, 1.0);
    return 1 + 0.035 * math.sin(math.pi * progress);
  }

  @override
  bool shouldRepaint(covariant _OlivOSMarkPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.lines != lines;
  }
}

class _LineGeometry {
  _LineGeometry._(
    this.id,
    this.startAt,
    this.duration,
    this.paths,
    this.drawStart,
    this.drawEnd,
    this.clipStart,
    this.normal,
    this.halfWidth,
  );

  final int id;
  final double startAt;
  final double duration;
  final List<Path> paths;
  final Offset drawStart;
  final Offset drawEnd;

  /// Position of the trailing edge of the reveal mask.
  ///
  /// The axis endpoint can sit in front of the line's actual start cap. If the
  /// mask starts there, the cap is hidden until the final full-path frame, then
  /// pops in. Start the mask behind the whole cap instead.
  final Offset clipStart;
  final Offset normal;
  final double halfWidth;

  factory _LineGeometry.fromLine(OlivOSMarkLine line, Rect visibleRect) {
    final firstPoint = line.polygons.first.first;
    var axisStart = firstPoint;
    var axisEnd = firstPoint;
    var length = 0.0;
    for (final polygon in line.polygons) {
      for (var index = 0; index < polygon.length; index++) {
        final candidateStart = polygon[index];
        final candidateEnd = polygon[(index + 1) % polygon.length];
        final candidateLength = (candidateEnd - candidateStart).distance;
        if (candidateLength > length) {
          axisStart = candidateStart;
          axisEnd = candidateEnd;
          length = candidateLength;
        }
      }
    }

    if (axisStart.dy > axisEnd.dy ||
        (axisStart.dy == axisEnd.dy && axisStart.dx > axisEnd.dx)) {
      final swap = axisStart;
      axisStart = axisEnd;
      axisEnd = swap;
    }

    final direction = (axisEnd - axisStart) / length;
    final polygons = [
      for (final polygon in line.polygons) [...polygon],
    ];
    var start = axisStart;
    var end = axisEnd;

    // Overscan generously: the cap must be completely outside the screen, and
    // the line's direction must not change to chase a corner.
    final margin = math.max(12.0, length * 0.3);
    Offset? endCapEntry;
    if (line.extendEnd) {
      end += _extendCap(
        polygons,
        start,
        direction,
        visibleRect,
        length,
        margin,
      );
      if (line.reverse) {
        endCapEntry = _capAnchor(polygons, start, direction, length);
      }
    }
    if (line.extendStart) {
      final reverse = -direction;
      start += _extendCap(polygons, end, reverse, visibleRect, length, margin);
    }

    // Start reverse extended lines at the actual outer cap. The clip then
    // includes the off-screen extension while paint() begins the visible cut
    // at the screen boundary; this keeps the lower end connected during the
    // whole animation instead of only at the final frame.
    final drawStart = line.reverse
        ? (line.extendEnd ? (endCapEntry ?? end) : axisEnd)
        : (line.extendEnd ? axisStart : start);
    final drawEnd = line.reverse ? (line.extendStart ? start : axisStart) : end;
    final drawAxis = drawEnd - drawStart;
    final drawDirection = drawAxis / drawAxis.distance;
    final normal = Offset(-drawDirection.dy, drawDirection.dx);

    var halfWidth = 0.0;
    var minProjection = 0.0;
    for (final polygon in polygons) {
      for (final point in polygon) {
        final fromStart = point - drawStart;
        final distance = fromStart.dx * normal.dx + fromStart.dy * normal.dy;
        halfWidth = math.max(halfWidth, distance.abs());
        final projection =
            fromStart.dx * drawDirection.dx + fromStart.dy * drawDirection.dy;
        minProjection = math.min(minProjection, projection);
      }
    }
    final clipStart = drawStart + drawDirection * (minProjection - 0.01);

    return _LineGeometry._(
      line.id,
      line.start,
      line.duration,
      [for (final polygon in polygons) Path()..addPolygon(polygon, true)],
      drawStart,
      drawEnd,
      clipStart,
      normal,
      halfWidth + 0.6,
    );
  }

  /// Moves one outer cap past the screen and returns the applied translation.
  static Offset _extendCap(
    List<List<Offset>> polygons,
    Offset fixed,
    Offset direction,
    Rect visibleRect,
    double length,
    double margin,
  ) {
    final cap = _capPoints(polygons, fixed, direction, length);
    if (cap.isEmpty) return Offset.zero;
    final exit = _capExitDistance(
      cap,
      polygons,
      direction,
      visibleRect,
      margin,
    );
    final delta = direction * exit;
    for (final projection in cap) {
      polygons[projection.polygonIndex][projection.pointIndex] += delta;
    }
    return delta;
  }

  /// Returns the cap point farthest along [direction].
  static Offset? _capAnchor(
    List<List<Offset>> polygons,
    Offset fixed,
    Offset direction,
    double length,
  ) {
    final cap = _capPoints(polygons, fixed, direction, length);
    if (cap.isEmpty) return null;
    var anchor = cap.first;
    for (final candidate in cap.skip(1)) {
      if (candidate.projection > anchor.projection) anchor = candidate;
    }
    return polygons[anchor.polygonIndex][anchor.pointIndex];
  }

  /// Translation distance that puts the whole cap past one screen edge.
  ///
  /// A cap is a short edge, not a point. Its two ends can exit through
  /// different screen edges, leaving part of the cut visible across a corner.
  /// For each edge the line can reach, solve for the translation that puts
  /// every cap point beyond that edge, then take the smallest of those
  /// distances. The cap therefore leaves through a single edge as a whole.
  static double _capExitDistance(
    List<_PointProjection> cap,
    List<List<Offset>> polygons,
    Offset direction,
    Rect rect,
    double margin,
  ) {
    double capDistance(double Function(Offset point) boundaryDistance) {
      var distance = 0.0;
      for (final projection in cap) {
        final point = polygons[projection.polygonIndex][projection.pointIndex];
        distance = math.max(distance, boundaryDistance(point));
      }
      return distance;
    }

    final distances = <double>[
      if (direction.dx > 0)
        capDistance((point) => (rect.right - point.dx) / direction.dx),
      if (direction.dx < 0)
        capDistance((point) => (rect.left - point.dx) / direction.dx),
      if (direction.dy > 0)
        capDistance((point) => (rect.bottom - point.dy) / direction.dy),
      if (direction.dy < 0)
        capDistance((point) => (rect.top - point.dy) / direction.dy),
    ];
    final exit = distances.isEmpty ? 0.0 : distances.reduce(math.min);
    return exit + margin;
  }

  /// Moves only the points on the outer end cap, preserving its cut angle.
  static List<_PointProjection> _capPoints(
    List<List<Offset>> polygons,
    Offset fixed,
    Offset direction,
    double length,
  ) {
    final projections = <_PointProjection>[];
    var maxProjection = double.negativeInfinity;
    for (final (polygonIndex, polygon) in polygons.indexed) {
      for (final (pointIndex, point) in polygon.indexed) {
        final projection =
            (point - fixed).dx * direction.dx +
            (point - fixed).dy * direction.dy;
        projections.add(_PointProjection(polygonIndex, pointIndex, projection));
        maxProjection = math.max(maxProjection, projection);
      }
    }

    // The cap is the narrow band of points at the outer end. Points further
    // back belong to the shaft and must not move, or the cut angle changes.
    final capBand = length * 0.25;
    return [
      for (final projection in projections)
        if (maxProjection - projection.projection <= capBand) projection,
    ];
  }

  void paint(Canvas canvas, double progress, Rect visibleRect) {
    if (paths.isEmpty) return;
    if (progress >= 0.999) {
      for (final path in paths) {
        canvas.drawPath(path, _OlivOSMarkPainter._paint);
      }
      return;
    }

    final cutStart = _entryPoint(drawStart, drawEnd, visibleRect) ?? drawStart;
    final cut = Offset.lerp(cutStart, drawEnd, progress)!;
    final clip = Path()
      ..addPolygon([
        clipStart + normal * halfWidth,
        clipStart - normal * halfWidth,
        cut - normal * halfWidth,
        cut + normal * halfWidth,
      ], true);

    canvas.save();
    canvas.clipPath(clip);
    for (final path in paths) {
      canvas.drawPath(path, _OlivOSMarkPainter._paint);
    }
    canvas.restore();
  }

  static Offset? _entryPoint(Offset from, Offset to, Rect rect) {
    final direction = to - from;
    final interval = _clipToRect(from, direction, rect, maxT: 1);
    if (interval == null) return null;
    return from + direction * interval.enter;
  }

  /// Clips the parametric line `origin + direction * t` against [rect].
  ///
  /// Returns the first and last visible `t`, constrained to `[0, maxT]`, or
  /// null when the line misses the rectangle.
  static ({double enter, double exit})? _clipToRect(
    Offset origin,
    Offset direction,
    Rect rect, {
    double maxT = double.infinity,
  }) {
    var enter = 0.0;
    var exit = maxT;

    bool clip(double p, double q) {
      if (p.abs() < 1e-9) return q >= 0;
      final ratio = q / p;
      if (p < 0) {
        if (ratio > exit) return false;
        if (ratio > enter) enter = ratio;
      } else {
        if (ratio < enter) return false;
        if (ratio < exit) exit = ratio;
      }
      return true;
    }

    if (!clip(-direction.dx, origin.dx - rect.left)) return null;
    if (!clip(direction.dx, rect.right - origin.dx)) return null;
    if (!clip(-direction.dy, origin.dy - rect.top)) return null;
    if (!clip(direction.dy, rect.bottom - origin.dy)) return null;
    if (enter > exit) return null;
    return (enter: enter, exit: exit);
  }
}

class _PointProjection {
  const _PointProjection(this.polygonIndex, this.pointIndex, this.projection);

  final int polygonIndex;
  final int pointIndex;
  final double projection;
}
