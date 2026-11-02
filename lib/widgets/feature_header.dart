import 'package:flutter/material.dart';
import 'unio_card.dart';
import 'signature_surface.dart';

/// A quiet, finite entrance; it never keeps an offscreen tab animating.
class FeatureReveal extends StatelessWidget {
  final Widget child;
  const FeatureReveal({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)), child: child)),
    );
  }
}

class FeatureHeader extends StatelessWidget {
  final String eyebrow, title, description;
  final IconData icon;
  final bool compact;
  const FeatureHeader(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.description,
      required this.icon,
      this.compact = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FeatureReveal(
        child: SignatureSurface(
      padding: EdgeInsets.all(compact ? 20 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: const Color(0xFFC9BAFF), size: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(eyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFD1D6ED), letterSpacing: .6)),
                const SizedBox(height: 4),
                Text(title,
                    style: (compact
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(color: Colors.white)),
              ])),
        ]),
        const SizedBox(height: 12),
        Text(description,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFFD1D6ED), height: 1.5)),
      ]),
    ));
  }
}

class FeatureLink extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color? accent;
  final VoidCallback? onTap;
  const FeatureLink(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      this.accent,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = this.accent ?? theme.colorScheme.primary;
    return UnioCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ])),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: theme.colorScheme.onSurfaceVariant)
            ],
          ],
        ));
  }
}
