import 'package:flutter/material.dart';

class LessonAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  const LessonAction(
      {required this.label,
      required this.icon,
      this.onTap,
      this.selected = false});
}

/// Horizontal tools stay reachable on narrow screens and with large text.
class LessonActions extends StatelessWidget {
  final List<LessonAction> actions;
  const LessonActions({super.key, required this.actions});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Semantics(
              selected: actions[i].selected,
              child: OutlinedButton.icon(
                onPressed: actions[i].onTap,
                icon: Icon(actions[i].icon, size: 19),
                label: Text(actions[i].label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: actions[i].selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  backgroundColor: actions[i].selected
                      ? colors.primaryContainer
                      : colors.surfaceContainerLow,
                  side: BorderSide(
                      color: actions[i].selected
                          ? colors.primary.withValues(alpha: .4)
                          : colors.outlineVariant),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
              )),
        ],
      ]),
    );
  }
}
