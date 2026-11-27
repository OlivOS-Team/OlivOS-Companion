import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'olivos_mark.dart';

/// Plays the OlivOS mark construction animation before revealing [child].
class LaunchGate extends StatefulWidget {
  const LaunchGate({
    super.key,
    required this.child,
    this.lines = olivosMarkLines,
    this.duration = const Duration(milliseconds: 2100),
  });

  final Widget child;

  /// Line definitions; their start/duration control the animation order.
  final List<OlivOSMarkLine> lines;

  final Duration duration;

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _appOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1, curve: Curves.easeOutCubic),
    );
    _splashOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.9, 1, curve: Curves.easeInCubic),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _finished = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _finished = true;
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
      label: 'OlivOS Companion 启动动画',
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
    final drawProgress = (value / 0.8).clamp(0.0, 1.0);
    final scale = _scaleAt(value);
    final aspect = olivosMarkBounds.width / olivosMarkBounds.height;
    final targetWidth = math.min(
      size.width * 0.62,
      size.height * 0.62 * aspect,
    );
    final fit = targetWidth / olivosMarkBounds.width;
    final effectiveScale = fit * scale;
    final center = olivosMarkBounds.center;
    final visibleRect = Rect.fromLTRB(
      (0 - size.width / 2) / effectiveScale + center.dx,
      (0 - size.height / 2) / effectiveScale + center.dy,
      (size.width - size.width / 2) / effectiveScale + center.dx,
      (size.height - size.height / 2) / effectiveScale + center.dy,
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
    if (value < 0.8 || value > 0.92) return 1;
    final progress = ((value - 0.8) / 0.12).clamp(0.0, 1.0);
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
    this.start,
    this.end,
    this.normal,
    this.halfWidth,
    this.screenEntryFrom,
    this.screenEntryTo,
  );

  final int id;
  final double startAt;
  final double duration;
  final List<Path> paths;
  final Offset start;
  final Offset end;
  final Offset normal;
  final double halfWidth;
  final Offset? screenEntryFrom;
  final Offset? screenEntryTo;

  factory _LineGeometry.fromLine(OlivOSMarkLine line, Rect visibleRect) {
    final allPoints = [for (final polygon in line.polygons) ...polygon];

    var axisStart = allPoints.first;
    var axisEnd = allPoints[1];
    var length = (axisEnd - axisStart).distance;
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
    final baseStart = axisStart;
    final baseEnd = axisEnd;
    var start = axisStart;
    var end = axisEnd;

    final hasStartExtension = line.extendStart;
    final hasEndExtension = line.extendEnd;
    // Overscan generously: the cap must be completely outside the screen, and
    // the line's direction must not change to chase a corner.
    final margin = math.max(12.0, length * 0.3);
    if (hasEndExtension) {
      final cap = _capPoints(polygons, start, direction, length);
      if (cap.isNotEmpty) {
        final exit = _capExitDistance(
          cap,
          polygons,
          direction,
          visibleRect,
          margin,
        );
        final delta = direction * exit;
        _moveCap(polygons, cap, delta);
        end += delta;
      }
    }
    if (hasStartExtension) {
      final reverse = -direction;
      final cap = _capPoints(polygons, end, reverse, length);
      if (cap.isNotEmpty) {
        final exit = _capExitDistance(
          cap,
          polygons,
          reverse,
          visibleRect,
          margin,
        );
        final delta = reverse * exit;
        _moveCap(polygons, cap, delta);
        start += delta;
      }
    }

    // Start reverse lines at the visible end so the off-screen extension does
    // not delay the beginning of the animation.
    final drawStart = line.reverse
        ? baseEnd
        : (hasEndExtension ? baseStart : start);
    final drawEnd = line.reverse
        ? (hasStartExtension ? start : baseStart)
        : end;
    final drawAxis = drawEnd - drawStart;
    final drawLength = drawAxis.distance;
    final drawDirection = drawAxis / drawLength;
    final normal = Offset(-drawDirection.dy, drawDirection.dx);

    var halfWidth = 0.0;
    for (final polygon in polygons) {
      for (final point in polygon) {
        final distance =
            (point - drawStart).dx * normal.dx +
            (point - drawStart).dy * normal.dy;
        halfWidth = math.max(halfWidth, distance.abs());
      }
    }

    // For reverse lines that extend past the lower-left edge, reveal them from
    // the screen boundary so the off-screen extension and the animated shaft
    // stay connected.
    final extendReverse = line.reverse && hasEndExtension;

    return _LineGeometry._(
      line.id,
      line.start,
      line.duration,
      [for (final polygon in polygons) Path()..addPolygon(polygon, true)],
      drawStart,
      drawEnd,
      normal,
      halfWidth + 0.6,
      extendReverse ? _outsidePoint(end, direction, visibleRect, margin) : null,
      extendReverse ? baseStart : null,
    );
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
    var exit = double.infinity;

    double capDistance(double Function(Offset point) boundaryDistance) {
      var distance = 0.0;
      for (final projection in cap) {
        final point = polygons[projection.polygonIndex][projection.pointIndex];
        distance = math.max(distance, boundaryDistance(point));
      }
      return distance;
    }

    if (direction.dx > 0) {
      exit = math.min(
        exit,
        capDistance((point) => (rect.right - point.dx) / direction.dx),
      );
    }
    if (direction.dx < 0) {
      exit = math.min(
        exit,
        capDistance((point) => (rect.left - point.dx) / direction.dx),
      );
    }
    if (direction.dy > 0) {
      exit = math.min(
        exit,
        capDistance((point) => (rect.bottom - point.dy) / direction.dy),
      );
    }
    if (direction.dy < 0) {
      exit = math.min(
        exit,
        capDistance((point) => (rect.top - point.dy) / direction.dy),
      );
    }

    return (exit.isFinite ? exit : 0.0) + margin;
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
    for (var polygonIndex = 0; polygonIndex < polygons.length; polygonIndex++) {
      final polygon = polygons[polygonIndex];
      for (var pointIndex = 0; pointIndex < polygon.length; pointIndex++) {
        final point = polygon[pointIndex];
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

  static void _moveCap(
    List<List<Offset>> polygons,
    List<_PointProjection> cap,
    Offset delta,
  ) {
    for (final projection in cap) {
      polygons[projection.polygonIndex][projection.pointIndex] += delta;
    }
  }

  void paint(Canvas canvas, double progress, Rect visibleRect) {
    if (paths.isEmpty) return;
    if (progress >= 0.999) {
      for (final path in paths) {
        canvas.drawPath(path, _OlivOSMarkPainter._paint);
      }
      return;
    }

    var paintStart = start;
    if (screenEntryFrom != null && screenEntryTo != null) {
      paintStart =
          _entryPoint(screenEntryFrom!, screenEntryTo!, visibleRect) ?? start;
    }
    final cut = Offset.lerp(paintStart, end, progress)!;
    final clip = Path()
      ..addPolygon([
        paintStart + normal * halfWidth,
        paintStart - normal * halfWidth,
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

  /// Moves [origin] past [rect] along [direction], with overscan.
  ///
  /// The extended cap can be outside while the axis endpoint is still inside;
  /// using the axis endpoint for the screen-entry reveal would then leave the
  /// extension disconnected until the animation finishes. This returns a point
  /// that is definitely outside the screen.
  static Offset _outsidePoint(
    Offset origin,
    Offset direction,
    Rect rect,
    double margin,
  ) {
    if (!rect.contains(origin)) return origin;

    var tMin = 0.0;
    var tMax = double.infinity;

    bool clip(double p, double q) {
      if (p.abs() < 1e-9) return q >= 0;
      final ratio = q / p;
      if (p < 0) {
        if (ratio > tMax) return false;
        if (ratio > tMin) tMin = ratio;
      } else {
        if (ratio < tMin) return false;
        if (ratio < tMax) tMax = ratio;
      }
      return true;
    }

    if (!clip(-direction.dx, origin.dx - rect.left)) {
      return origin + direction * margin;
    }
    if (!clip(direction.dx, rect.right - origin.dx)) {
      return origin + direction * margin;
    }
    if (!clip(-direction.dy, origin.dy - rect.top)) {
      return origin + direction * margin;
    }
    if (!clip(direction.dy, rect.bottom - origin.dy)) {
      return origin + direction * margin;
    }
    if (tMax < 0 || tMin > tMax || !tMax.isFinite) {
      return origin + direction * margin;
    }
    return origin + direction * (tMax + margin);
  }

  static Offset? _entryPoint(Offset from, Offset to, Rect rect) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    var t0 = 0.0;
    var t1 = 1.0;

    bool clip(double p, double q) {
      if (p.abs() < 1e-9) return q >= 0;
      final ratio = q / p;
      if (p < 0) {
        if (ratio > t1) return false;
        if (ratio > t0) t0 = ratio;
      } else {
        if (ratio < t0) return false;
        if (ratio < t1) t1 = ratio;
      }
      return true;
    }

    if (!clip(-dx, from.dx - rect.left)) return null;
    if (!clip(dx, rect.right - from.dx)) return null;
    if (!clip(-dy, from.dy - rect.top)) return null;
    if (!clip(dy, rect.bottom - from.dy)) return null;
    if (t0 > t1) return null;
    return from + Offset(dx, dy) * t0;
  }
}

class _PointProjection {
  const _PointProjection(this.polygonIndex, this.pointIndex, this.projection);

  final int polygonIndex;
  final int pointIndex;
  final double projection;
}
