import '../services/locale_service.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const welcomeBackground = Color(0xFF0B0D18);
const welcomeSurface = Color(0xFF191D30);
const welcomeAccent = Color(0xFFAD98FF);
const welcomeMuted = Color(0xFFA7ABC0);

/// A finite entrance animation: no perpetual ticker while someone reads a page.
class WelcomeReveal extends StatelessWidget {
  final Widget child;
  final double delay;
  const WelcomeReveal({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      child: child,
      builder: (context, value, child) {
        final progress = Curves.easeOutCubic
            .transform(((value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Opacity(
          opacity: progress,
          child: Transform.translate(
              offset: Offset(0, 26 * (1 - progress)), child: child),
        );
      },
    );
  }
}

class WelcomeWordmark extends StatelessWidget {
  const WelcomeWordmark({super.key});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/icon/icon.png',
          width: 32, height: 32, excludeFromSemantics: true),
      const SizedBox(width: 9),
      const Text('unio',
          style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1))
    ]);
  }
}

class WelcomeBackdrop extends StatefulWidget {
  final Widget child;
  const WelcomeBackdrop({super.key, required this.child});
  @override
  State<WelcomeBackdrop> createState() => _WelcomeBackdropState();
}

class _WelcomeBackdropState extends State<WelcomeBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));
  bool _reducedMotion = false, _visible = true, _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (_reducedMotion || !_visible || !_active) {
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
    return Stack(fit: StackFit.expand, children: [
      Positioned.fill(
          child: IgnorePointer(
              child: RepaintBoundary(
                  child: CustomPaint(painter: _BrandFlowPainter(_motion))))),
      widget.child
    ]);
  }
}

/// Gradients and paths are painted directly, without full-screen blur filters.
/// Only this repaint boundary ticks; forms and text do not rebuild each frame.
class _BrandFlowPainter extends CustomPainter {
  final Animation<double> motion;
  _BrandFlowPainter(this.motion) : super(repaint: motion);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(welcomeBackground, BlendMode.src);
    final phase = motion.value * math.pi * 2;
    final extent = math.max(size.width, size.height);
    void glow(Offset center, double radius, Color color) {
      final bounds = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0, 1],
            ).createShader(bounds));
    }

    glow(
        Offset(size.width * (.83 + .22 * math.sin(phase)),
            size.height * (.16 + .13 * math.cos(phase))),
        extent * .67,
        const Color(0x685B2DDD));
    glow(
        Offset(size.width * (.02 + .25 * math.cos(phase)),
            size.height * (.7 + .13 * math.sin(phase))),
        extent * .56,
        const Color(0x48204CDA));
    glow(Offset(size.width * .65, size.height * (.98 + .1 * math.cos(phase))),
        extent * .40, const Color(0x304D217E));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      paint.color = welcomeAccent.withValues(alpha: .035 + i * .012);
      final path = Path()
        ..moveTo(-size.width * .2, size.height * (.24 + i * .10));
      path.cubicTo(
          size.width * (.2 + .09 * math.sin(phase)),
          -size.height * .15,
          size.width * .95,
          size.height * (.7 + .1 * math.cos(phase + i)),
          size.width * 1.15,
          size.height * (.28 + i * .13));
      canvas.drawPath(path, paint);
    }
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < 16; i++) {
      final x = ((i * .6180339) % 1) * size.width + math.sin(phase + i) * 10;
      final y =
          ((i * .381966 + .1) % 1) * size.height + math.cos(phase + i) * 14;
      paint.color = welcomeAccent.withValues(
          alpha: .10 + .10 * (1 + math.sin(phase + i)) / 2);
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 1.8 : 1, paint);
    }
  }

  @override
  bool shouldRepaint(_BrandFlowPainter oldDelegate) =>
      oldDelegate.motion != motion;
}

class WelcomePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  const WelcomePill(this.label,
      {super.key, this.icon, this.color = welcomeAccent});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: color.withValues(alpha: .18))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7)
          ],
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)))
        ]));
  }
}

/// Decorative previews only. All explanatory content lives in scalable text
/// outside this canvas; preview cards are not real schedule or request data.
class WelcomeArtwork extends StatelessWidget {
  final int page;
  final double displacement;
  const WelcomeArtwork({super.key, required this.page, this.displacement = 0});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return ExcludeSemantics(
        child: RepaintBoundary(
            child: FittedBox(
                fit: BoxFit.contain,
                child: MediaQuery.withNoTextScaling(
                    child: SizedBox(
                        width: 350,
                        height: 300,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Positioned.fill(
                              child: CustomPaint(painter: _OrbitPainter(page))),
                          Transform.translate(
                              offset: Offset(displacement * 22, 0),
                              child: switch (page) {
                                0 => _university(),
                                1 => _schedule(),
                                2 => _requests(),
                                _ => _people()
                              })
                        ]))))));
  }

  Widget _university() => Stack(children: [
        Positioned(
            left: 112,
            top: 65,
            child: Transform.rotate(
                angle: -.09,
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x605B39DB),
                              blurRadius: 70,
                              spreadRadius: 2)
                        ]),
                    child: Image.asset('assets/icon/icon.png',
                        width: 132, height: 132)))),
        Positioned(
            left: 5,
            top: 35,
            child: Transform.rotate(
                angle: -.08,
                child: _tile(Icons.calendar_today_rounded, l10n.uiSchedule,
                    l10n.uiClassesForTheWeek, const Color(0xFFB6A0FF)))),
        Positioned(
            right: 0,
            top: 176,
            child: Transform.rotate(
                angle: .07,
                child: _tile(Icons.auto_stories_rounded, l10n.uiUniversity,
                    l10n.uiAlwaysNearby, const Color(0xFF80C8FF)))),
        Positioned(
            left: 19,
            bottom: 19,
            child: WelcomePill(l10n.uiForYourStudies470,
                icon: Icons.bolt_rounded, color: Color(0xFF9DE7CA))),
      ]);

  Widget _schedule() => Stack(children: [
        Positioned(
            left: 22,
            top: 22,
            right: 22,
            child: Transform.rotate(
                angle: -.035,
                child: _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(l10n.uiYourDay471,
                            style: TextStyle(
                                color: welcomeMuted,
                                fontSize: 10,
                                letterSpacing: 2)),
                        Spacer(),
                        Icon(Icons.more_horiz, color: welcomeMuted, size: 20)
                      ]),
                      const SizedBox(height: 14),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final day in [
                              l10n.uiMon,
                              l10n.uiTue,
                              l10n.uiWed,
                              l10n.uiThu,
                              l10n.uiFri
                            ])
                              Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: day == l10n.uiWed
                                          ? welcomeAccent
                                          : Colors.white.withValues(alpha: .04),
                                      borderRadius: BorderRadius.circular(13)),
                                  child: Text(day,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: day == l10n.uiWed
                                              ? welcomeBackground
                                              : welcomeMuted))),
                          ]),
                      const SizedBox(height: 20),
                      _lesson('10:10', l10n.uiForeignLanguage399,
                          l10n.uiRoom374, welcomeAccent),
                      const SizedBox(height: 17),
                      _lesson('11:50', l10n.uiPedagogy472, l10n.uiRoom376,
                          const Color(0xFF80C8FF)),
                    ])))),
        Positioned(
            right: 1,
            bottom: 13,
            child: Transform.rotate(
                angle: .045,
                child: _tile(Icons.wifi_off_rounded, l10n.uiEvenOffline,
                    l10n.uiSavedOnThisDevice, const Color(0xFF9DE7CA)))),
      ]);

  Widget _requests() => Stack(children: [
        Positioned(
            left: 45,
            top: 22,
            right: 37,
            child: Transform.rotate(
                angle: .055,
                child: _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: welcomeAccent.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.description_outlined,
                              size: 28, color: welcomeAccent)),
                      const SizedBox(height: 17),
                      Text(l10n.uiEnrolmentCertificate,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 7),
                      Text(l10n.uiApplicationSubmitted,
                          style: TextStyle(color: welcomeMuted, fontSize: 12)),
                      const SizedBox(height: 22),
                      Row(children: [
                        for (var i = 0; i < 3; i++) ...[
                          Icon(
                              i < 2
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: i < 2
                                  ? const Color(0xFF9DE7CA)
                                  : welcomeMuted,
                              size: 22),
                          if (i < 2)
                            Expanded(
                                child: Container(
                                    height: 2, color: const Color(0xFF354252))),
                        ]
                      ]),
                      const SizedBox(height: 13),
                      Text(l10n.uiSubmittedInProgressReady,
                          style: TextStyle(color: welcomeMuted, fontSize: 10)),
                    ])))),
        Positioned(
            left: 0,
            bottom: 9,
            child: Transform.rotate(
                angle: -.055,
                child: _tile(
                    Icons.notifications_active_outlined,
                    l10n.uiCertificateReady,
                    l10n.uiReadyToCollect,
                    const Color(0xFF9DE7CA)))),
      ]);

  Widget _people() => Stack(children: [
        Positioned(
            left: 14,
            top: 22,
            right: 14,
            child: Transform.rotate(
                angle: -.03,
                child: _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .06),
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Icon(Icons.search, color: welcomeAccent, size: 20),
                            SizedBox(width: 8),
                            Text(l10n.uiFindATeacher,
                                style: TextStyle(
                                    color: welcomeMuted, fontSize: 13))
                          ])),
                      const SizedBox(height: 19),
                      Row(children: [
                        CircleAvatar(
                            backgroundColor: Color(0xFF363051),
                            child: Icon(Icons.person_outline_rounded,
                                color: welcomeAccent)),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(l10n.uiTeacherClassSchedule,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.6)))
                      ]),
                      const SizedBox(height: 18),
                      WelcomePill(l10n.uiNextClassRoom,
                          icon: Icons.place_outlined, color: Color(0xFF80C8FF)),
                    ])))),
        Positioned(
            right: 0,
            bottom: 15,
            child: Transform.rotate(
                angle: .055,
                child: _tile(Icons.edit_note_rounded, l10n.uiEssentialsAtHand,
                    l10n.uiClassNotes, welcomeAccent))),
      ]);

  Widget _lesson(String time, String title, String room, Color color) =>
      Row(children: [
        Text(time, style: const TextStyle(color: welcomeMuted, fontSize: 13)),
        const SizedBox(width: 12),
        Container(width: 3, height: 38, color: color),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(room, style: const TextStyle(color: welcomeMuted, fontSize: 11))
        ])),
      ]);

  Widget _tile(IconData icon, String title, String subtitle, Color color) =>
      _panel(
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 22, color: color)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: welcomeMuted, fontSize: 10)),
            ]),
          ]),
          padding: 14);

  Widget _panel(Widget child, {double padding = 20}) => Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF272940), Color(0xFF181C2D)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3B3B57)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x44000000), blurRadius: 28, offset: Offset(0, 16))
          ]),
      child: child);
}

class _OrbitPainter extends CustomPainter {
  final int page;
  const _OrbitPainter(this.page);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = welcomeAccent.withValues(alpha: .10);
    canvas.drawCircle(center, 132, paint);
    canvas.drawCircle(center, 163, paint);
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + page * .4;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * 142;
      paint.color = (i.isEven ? welcomeAccent : const Color(0xFF80C8FF))
          .withValues(alpha: .5);
      canvas.drawCircle(point, i.isEven ? 3 : 2, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => oldDelegate.page != page;
}
