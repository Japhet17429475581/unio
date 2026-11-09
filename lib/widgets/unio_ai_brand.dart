import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'unio_ai_motion.dart';

/// The original UNIO AI three-sparkle icon. Motion changes only its tint,
/// preserving the familiar Material shape at every size.
class UnioAiMark extends StatelessWidget {
  final double size;
  final bool muted;
  const UnioAiMark({super.key, this.size = 24, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = muted
        ? theme.colorScheme.onSurfaceVariant
        : theme.brightness == Brightness.dark
            ? Colors.white
            : theme.colorScheme.onSurface;
    final icon = Icon(Icons.auto_awesome_rounded, size: size, color: base);
    final motion = muted ? null : AiMotionScope.maybeOf(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: motion == null
            ? icon
            : AnimatedBuilder(
                animation: motion.repaint,
                child: RepaintBoundary(child: icon),
                builder: (context, child) {
                  final energy = motion.energy.value;
                  return ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (rect) => LinearGradient(
                      colors: [
                        Color.lerp(base, theme.colorScheme.primary, energy)!,
                        Color.lerp(base, const Color(0xFF8EA5EA), energy)!
                      ],
                      transform: GradientRotation(
                          math.sin(motion.progress * math.pi * 2) * .7),
                    ).createShader(rect),
                    child: child,
                  );
                },
              ),
      ),
    );
  }
}

class UnioAiWordmark extends StatelessWidget {
  const UnioAiWordmark({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const UnioAiMark(size: 25),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              'UNIO AI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -.3),
            ),
          ),
        ],
      );
}
