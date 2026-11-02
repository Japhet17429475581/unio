import 'package:flutter/material.dart';
import '../config/brand.dart';
import '../config/calm_depth.dart';

BoxDecoration unioCardDecoration(BuildContext context,
    {double radius = 22, bool elevated = false}) {
  final theme = Theme.of(context);
  final signature = theme.extension<UnioSignature>() != null;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: theme.colorScheme.surface,
    gradient: signature
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              Color.lerp(
                  theme.colorScheme.surface, theme.colorScheme.primary, .035)!
            ],
          )
        : null,
    border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: .8)),
    boxShadow: elevated || signature
        ? [
            BoxShadow(
              color: const Color(0xFF211448)
                  .withValues(alpha: elevated ? .12 : .04),
              blurRadius: elevated ? 24 : 16,
              offset: const Offset(0, 6),
            )
          ]
        : null,
  );
}

class UnioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool elevated;
  const UnioCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(UnioSpacing.lg),
      this.radius = 22,
      this.onTap,
      this.elevated = false});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration:
              unioCardDecoration(context, radius: radius, elevated: elevated),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}
