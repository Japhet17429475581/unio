import 'package:flutter/material.dart';
import 'unio_ai_brand.dart';

/// Plain monochrome icon with a 48px touch target and no decorative background.
class AssistantEntryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AssistantEntryButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        tooltip: 'UNIO AI',
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.all(12),
        style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            overlayColor: WidgetStatePropertyAll(Colors.transparent)),
        icon: const UnioAiMark());
  }
}
