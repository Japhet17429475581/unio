import 'package:flutter/material.dart';

/// Plain monochrome icon with a 48px touch target and no decorative background.
class AssistantEntryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AssistantEntryButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
        tooltip: 'UNIO AI',
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.all(12),
        style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            overlayColor: WidgetStatePropertyAll(Colors.transparent)),
        icon: Icon(Icons.auto_awesome_rounded,
            size: 24,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : theme.colorScheme.onSurface));
  }
}
