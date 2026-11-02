import 'package:flutter/material.dart';
import '../services/locale_service.dart';

class StoryCircle extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData icon;
  final bool seen;
  final VoidCallback onTap;
  const StoryCircle(
      {super.key,
      required this.label,
      this.imageUrl,
      this.icon = Icons.article_outlined,
      this.seen = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
        color: colors.surfaceContainer,
        child: Center(child: Icon(icon, color: colors.primary, size: 24)));
    return Semantics(
        button: true,
        excludeSemantics: true,
        onTap: onTap,
        label: '$label. ${seen ? l10n.storyViewed : l10n.open}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                seen ? colors.outlineVariant : colors.primary,
                            width: 1.5)),
                    child: ClipOval(
                        child: imageUrl?.isNotEmpty == true
                            ? Image.network(imageUrl!,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.fallback,
                                fit: BoxFit.cover,
                                cacheWidth: 168,
                                errorBuilder: (_, __, ___) => fallback)
                            : fallback)),
                const SizedBox(height: 8),
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall),
              ])),
        ));
  }
}
