import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One motion clock for the whole chat. Painters repaint without rebuilding
/// messages. Idle entrance is finite; looping is reserved for real requests.
class UnioAiMotion extends StatefulWidget {
  final bool busy;
  final bool writing;
  final Widget child;
  const UnioAiMotion(
      {super.key,
      required this.busy,
      this.writing = false,
      required this.child});

  @override
  State<UnioAiMotion> createState() => _UnioAiMotionState();
}

class _UnioAiMotionState extends State<UnioAiMotion>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _phase = AnimationController(vsync: this);
  late final AnimationController _energy = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
  late final Listenable _repaint = Listenable.merge([_phase, _energy]);
  bool _visible = true;
  bool _entered = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _energy.addStatusListener(_settled);
  }

  void _settled(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !widget.busy) _phase.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant UnioAiMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy || oldWidget.writing != widget.writing)
      _sync();
  }

  void _sync() {
    _enabled = _visible &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!_enabled) {
      _phase.stop();
      _energy.stop();
      // No residual movement or partially active visual state in reduced motion.
      _energy.value = widget.busy ? 1 : 0;
      return;
    }
    if (widget.busy) {
      _entered = true;
      _phase.duration = Duration(milliseconds: widget.writing ? 2600 : 3800);
      _phase.repeat();
      _energy.forward();
    } else if (_energy.value > 0) {
      _energy.reverse();
    } else if (!_entered) {
      _entered = true;
      _phase.duration = const Duration(milliseconds: 1100);
      _phase.forward();
    } else {
      _phase.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (mounted) setState(_sync);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _energy.removeStatusListener(_settled);
    _phase.dispose();
    _energy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AiMotionScope(
      phase: _phase,
      energy: _energy,
      repaint: _repaint,
      enabled: _enabled,
      child: widget.child);
}

/// Animation values are read only by painters, not by the message list.
class AiMotionScope extends InheritedWidget {
  final Animation<double> phase;
  final Animation<double> energy;
  final Listenable repaint;
  final bool enabled;
  const AiMotionScope(
      {super.key,
      required this.phase,
      required this.energy,
      required this.repaint,
      required this.enabled,
      required super.child});

  static AiMotionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AiMotionScope>();

  double get progress => enabled ? phase.value : 0;

  @override
  bool updateShouldNotify(AiMotionScope oldWidget) =>
      oldWidget.enabled != enabled || oldWidget.phase != phase;
}

/// Soft, bounded washes only on a new chat or during an actual request.
/// Radial shaders avoid blur filters and do not affect content contrast.
class UnioAiAtmosphere extends StatelessWidget {
  final bool empty;
  final Widget child;
  const UnioAiAtmosphere({super.key, required this.empty, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _AtmospherePainter(
          motion: AiMotionScope.maybeOf(context),
          empty: empty,
          dark: Theme.of(context).brightness == Brightness.dark,
          purple: colors.primary),
      child: RepaintBoundary(child: child),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final AiMotionScope? motion;
  final bool empty, dark;
  final Color purple;
  _AtmospherePainter(
      {required this.motion,
      required this.empty,
      required this.dark,
      required this.purple})
      : super(repaint: motion?.repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final energy = motion?.energy.value ?? 0;
    final strength = empty ? 1.0 : energy;
    if (strength == 0) return;
    final phase = (motion?.progress ?? 0) * math.pi * 2;
    final radius = math.min(size.width * .9, 520.0);
    final band = math.min(size.height * .65, 440.0);
    final y = empty ? size.height - band * .12 : band * .05;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    for (var i = 0; i < 2; i++) {
      final center = Offset(
          size.width * (i == 0 ? .28 : .76) + math.sin(phase + i) * 18,
          y + math.cos(phase + i) * 14);
      final tint = i == 0 ? purple : const Color(0xFF718BE1);
      final alpha = (dark ? .12 : .075) * strength;
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(colors: [
              tint.withValues(alpha: alpha),
              tint.withValues(alpha: 0)
            ], stops: const [
              0,
              1
            ]).createShader(Rect.fromCircle(center: center, radius: radius)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) =>
      old.motion != motion ||
      old.empty != empty ||
      old.dark != dark ||
      old.purple != purple;
}

/// A narrow responsive edge, instead of an animated panel behind the text.
class UnioAiComposerSurface extends StatelessWidget {
  final bool focused;
  final Widget child;
  const UnioAiComposerSurface(
      {super.key, required this.focused, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      foregroundPainter: _ComposerEdge(
          motion: AiMotionScope.maybeOf(context),
          focused: focused,
          primary: colors.primary,
          outline: colors.outlineVariant),
      child: DecoratedBox(
          decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(26)),
          child: RepaintBoundary(child: child)),
    );
  }
}

class _ComposerEdge extends CustomPainter {
  final AiMotionScope? motion;
  final bool focused;
  final Color primary, outline;
  _ComposerEdge(
      {required this.motion,
      required this.focused,
      required this.primary,
      required this.outline})
      : super(repaint: motion?.repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final energy = motion?.energy.value ?? 0;
    final level = focused ? 1.0 : energy;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    if (level > 0) {
      paint.shader = SweepGradient(
          transform: GradientRotation((motion?.progress ?? 0) * math.pi * 2),
          colors: [
            Color.lerp(outline, primary, level * .65)!,
            Color.lerp(outline, const Color(0xFF8EA5EA), level * .55)!,
            Color.lerp(outline, primary, level * .65)!
          ]).createShader(Offset.zero & size);
    } else {
      paint.color = outline.withValues(alpha: .55);
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (Offset.zero & size).deflate(.6), const Radius.circular(26)),
        paint);
  }

  @override
  bool shouldRepaint(_ComposerEdge old) =>
      old.motion != motion ||
      old.focused != focused ||
      old.primary != primary ||
      old.outline != outline;
}
