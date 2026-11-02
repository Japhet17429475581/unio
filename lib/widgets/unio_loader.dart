import '../services/locale_service.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/brand.dart';

/// Decorative, indeterminate liquid inside the flat Unio mark.
/// No progress value or completion delay: remove it as soon as data is ready.
class UnioLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? semanticLabel;

  const UnioLoader({super.key, this.size = 80, this.color, this.semanticLabel});

  @override
  State<UnioLoader> createState() => _UnioLoaderState();
}

class _UnioLoaderState extends State<UnioLoader>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600));
  bool _visible = true;
  bool _reducedMotion = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _active = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (!_active || !_visible || _reducedMotion) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Semantics(
        label: widget.semanticLabel ?? l10n.uiLoading,
        image: true,
        child: SizedBox.square(
            dimension: widget.size,
            child: RepaintBoundary(
                child: CustomPaint(
                    painter: _LiquidMarkPainter(
                        motion: _motion,
                        color: widget.color,
                        dark: Theme.of(context).brightness ==
                            Brightness.dark)))));
  }
}

class _LiquidMarkPainter extends CustomPainter {
  final Animation<double> motion;
  final Color? color;
  final bool dark;
  _LiquidMarkPainter(
      {required this.motion, required this.color, required this.dark})
      : super(repaint: motion);

  // Vector silhouette of the U from the app icon, with its slanted upper tips.
  static final Path _mark = Path()
    ..moveTo(7, 6)
    ..quadraticBezierTo(3, 3, 3, 9)
    ..lineTo(3, 53)
    ..cubicTo(3, 82, 23, 99, 50, 99)
    ..cubicTo(77, 99, 97, 82, 97, 53)
    ..lineTo(97, 9)
    ..quadraticBezierTo(97, 3, 93, 6)
    ..lineTo(72, 18)
    ..quadraticBezierTo(66, 22, 66, 30)
    ..lineTo(66, 55)
    ..cubicTo(66, 68, 61, 76, 50, 76)
    ..cubicTo(39, 76, 34, 68, 34, 55)
    ..lineTo(34, 30)
    ..quadraticBezierTo(34, 22, 28, 18)
    ..close();

  Path _wave(double baseline, double amplitude, double phase) {
    final path = Path()..moveTo(-2, 104);
    for (var x = -2; x <= 102; x += 2) {
      final y = baseline + math.sin(x / 100 * math.pi * 2 + phase) * amplitude;
      path.lineTo(x.toDouble(), y);
    }
    return path
      ..lineTo(102, 104)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;
    final phase = motion.value * math.pi * 2;
    final blue = color ?? unioBlue;
    final violet =
        color == null ? unioViolet : Color.lerp(color, Colors.white, .4)!;
    final baseline = 48 + math.sin(phase) * 22;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 104, side / 104);
    canvas.translate(2, 0);
    canvas.drawPath(
        _mark,
        Paint()
          ..color = (color ?? (dark ? const Color(0xFFAAA0E8) : unioViolet))
              .withValues(alpha: dark ? .23 : .10));
    canvas.save();
    canvas.clipPath(_mark);
    canvas.drawPath(_wave(baseline - 7, 5, -phase + 1),
        Paint()..color = blue.withValues(alpha: .38));
    canvas.drawPath(
        _wave(baseline, 6, phase),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(-1, -.5 + .5 * math.cos(phase)),
            end: Alignment(1, .5 + .5 * math.sin(phase)),
            colors: [blue, violet],
          ).createShader(const Rect.fromLTWH(0, 0, 100, 104)));
    canvas.restore();
    canvas.drawPath(
        _mark,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = (color ?? (dark ? const Color(0xFFB9A8FF) : unioViolet))
              .withValues(alpha: .27));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiquidMarkPainter oldDelegate) =>
      oldDelegate.motion != motion ||
      oldDelegate.color != color ||
      oldDelegate.dark != dark;
}

/// Keep Flutter's pull-to-refresh gesture and future handling, replace its ring.
class UnioRefreshIndicator extends StatefulWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  const UnioRefreshIndicator(
      {super.key, required this.child, required this.onRefresh});
  @override
  State<UnioRefreshIndicator> createState() => _UnioRefreshIndicatorState();
}

class _UnioRefreshIndicatorState extends State<UnioRefreshIndicator> {
  RefreshIndicatorStatus? _status;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final visible = _status != null &&
        _status != RefreshIndicatorStatus.canceled &&
        _status != RefreshIndicatorStatus.done;
    return Stack(children: [
      RefreshIndicator.noSpinner(
        onRefresh: widget.onRefresh,
        onStatusChange: (status) {
          if (mounted) setState(() => _status = status);
        },
        child: widget.child,
      ),
      if (visible)
        Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
                child: Center(
                    child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 3,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child:
                      UnioLoader(size: 32, semanticLabel: l10n.uiRefreshing)),
            )))),
    ]);
  }
}
