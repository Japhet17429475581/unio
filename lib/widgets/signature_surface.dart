import 'package:flutter/material.dart';
import '../config/calm_depth.dart';

/// The brand's folded curves stay in the background, away from readable content.
class SignatureSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SignatureSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(22)});

  @override
  Widget build(BuildContext context) {
    final signature =
        Theme.of(context).extension<UnioSignature>() ?? const UnioSignature();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: signature.start.withValues(alpha: .20),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  signature.start,
                  const Color(0xFF25214B),
                  signature.end
                ]),
            border: Border.all(color: signature.accent.withValues(alpha: .28)),
            borderRadius: BorderRadius.circular(26),
          ),
          child: CustomPaint(
              painter: _SignatureContours(signature.accent),
              child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

class _SignatureContours extends CustomPainter {
  final Color accent;
  const _SignatureContours(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final glow = Rect.fromCircle(center: Offset(size.width, 0), radius: 180);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: .16),
              accent.withValues(alpha: 0)
            ],
          ).createShader(glow));
    // Cropped arcs recall the U's rounded fold without drawing a letter over text.
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width - 68 - i * 23, -92, 144 + i * 46,
                  size.height + 125),
              const Radius.circular(100)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = accent.withValues(alpha: .09));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SignatureContours oldDelegate) =>
      accent != oldDelegate.accent;
}

/// A static atmospheric wash: no perpetual animations on working screens.
class SignatureBackdrop extends StatelessWidget {
  final Widget child;
  const SignatureBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: DecoratedBox(
            decoration: BoxDecoration(
                gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.35,
                    colors: [
                  dark ? const Color(0xFF232044) : const Color(0xFFECE6FC),
                  theme.scaffoldBackgroundColor
                ],
                    stops: const [
                  0,
                  .8
                ])),
            child: child));
  }
}
