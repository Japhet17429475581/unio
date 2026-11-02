import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gives enlarged navigation labels enough room without reducing text scaling.
class UnioNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<NavigationDestination> destinations;
  const UnioNavigationBar(
      {super.key,
      this.selectedIndex = 0,
      this.onDestinationSelected,
      required this.destinations});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final theme = Theme.of(context);
        var labelHeight = 0.0;
        for (var index = 0; index < destinations.length; index++) {
          final style = theme.navigationBarTheme.labelTextStyle?.resolve(
                  index == selectedIndex ? {WidgetState.selected} : {}) ??
              theme.textTheme.labelMedium!;
          final painter = TextPainter(
            text: TextSpan(text: destinations[index].label, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(
              maxWidth:
                  math.max(1, constraints.maxWidth / destinations.length - 8));
          labelHeight = math.max(labelHeight, painter.height);
          painter.dispose();
        }
        return DecoratedBox(
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: .7)))),
            child: NavigationBar(
              height: math.max(72, labelHeight + 56),
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ));
      });
}
