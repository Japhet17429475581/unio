import 'package:flutter/material.dart';
import '../config/calm_depth.dart';

import 'tap_feedback.dart';

class Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const Message({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calm = theme.extension<UnioSignature>() != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(calm ? 24 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: calm ? 40 : 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: calm ? theme.colorScheme.onSurfaceVariant : Colors.grey,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: PrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  borderRadius: calm ? CalmDepth.controlRadius : 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
