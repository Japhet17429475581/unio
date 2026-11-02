import '../services/locale_service.dart';
import 'package:flutter/material.dart';

import '../models/portal_request.dart';
import '../services/request_status_service.dart' show isRequestReady;
import 'unio_card.dart';

/// Presentation only: never infer readiness or allow editing from a colour.
class RequestCard extends StatelessWidget {
  final RequestListItem item;
  final VoidCallback onTap;
  const RequestCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = item.normalizedStatus;
    final ready = isRequestReady(item.status);
    final rejected = {'отклонено', 'отклонен', 'отклонена', 'отказано', 'отказ'}
        .contains(status);
    final pending = item.isNew ||
        {
          'в обработке',
          'на обработке',
          'обработка',
          'принято',
          'на рассмотрении',
          'в работе'
        }.contains(status);
    final accent = ready
        ? colors.tertiary
        : rejected
            ? colors.error
            : item.canFill
                ? colors.primary
                : pending
                    ? Color.lerp(
                        const Color(0xFFC48124), colors.onSurface, .25)!
                    : colors.onSurfaceVariant;
    final statusIcon = ready
        ? Icons.check_circle_outline_rounded
        : rejected
            ? Icons.error_outline_rounded
            : item.canFill
                ? Icons.edit_outlined
                : pending
                    ? Icons.schedule_rounded
                    : Icons.info_outline_rounded;
    return UnioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.description_outlined,
                  size: 22, color: colors.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                    [if (item.category.isNotEmpty) item.category, '№${item.id}']
                        .join(' · '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
              ])),
          if (item.canFill)
            Icon(Icons.arrow_forward_rounded, color: colors.primary, size: 20),
        ]),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, size: 18, color: accent),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(item.displayStatus,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: accent))),
            ])),
        if (item.isNew) ...[
          const SizedBox(height: 10),
          Text(l10n.uiThePortalIsPreparingYourForm,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ],
        if (item.updated.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(item.updated,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ]),
    );
  }
}
