import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../services/home_widget_service.dart';
import '../utils/user_messages.dart';
import 'signature_surface.dart';
import 'tap_feedback.dart';

Future<void> showHomeWidgetSheet(BuildContext context,
        {required String label}) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => _HomeWidgetSheet(label: label));

class _HomeWidgetSheet extends StatefulWidget {
  final String label;
  const _HomeWidgetSheet({required this.label});
  @override
  State<_HomeWidgetSheet> createState() => _HomeWidgetSheetState();
}

class _HomeWidgetSheetState extends State<_HomeWidgetSheet> {
  bool? _pinSupported;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    homeWidget.canPin().then((value) {
      if (mounted) setState(() => _pinSupported = value);
    }).catchError((Object _) {
      if (mounted) setState(() => _pinSupported = false);
    });
  }

  Future<void> _add() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final requested = await homeWidget.pin();
      if (!mounted) return;
      setState(() => _message = requested
          ? l10n.uiConfirmInTheAndroidDialogTheWidgetWill
          : l10n.uiTouchAndHoldAnEmptyAreaOnYour);
    } catch (error) {
      if (mounted) setState(() => _message = userMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 24 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.uiYourScheduleAtHand,
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.uiYourNextClassAndRoomRightOnYour,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            SignatureSurface(
                child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium!
                        .copyWith(color: Colors.white),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('unio',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(color: Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(widget.label,
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFFD5C9FF),
                                        fontSize: 12))),
                          ]),
                          const SizedBox(height: 20),
                          Text(l10n.uiNextClassToday,
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  color: Color(0xFFC8B6F4))),
                          const SizedBox(height: 8),
                          Text('11:30–13:00',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(l10n.uiForeignLanguage399,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(l10n.uiPracticalRoom,
                              style: TextStyle(
                                  color: Color(0xFFD4CBE6), fontSize: 13)),
                          const SizedBox(height: 18),
                          Row(children: [
                            Expanded(
                                child: Text(l10n.uiYourDayYourPace,
                                    style: TextStyle(
                                        color: Color(0xFFCDC4DF),
                                        fontSize: 11))),
                            Icon(Icons.refresh_rounded,
                                color: Color(0xFFD5C9FF), size: 20),
                          ]),
                        ]))),
            const SizedBox(height: 12),
            Text(l10n.uiDesignPreviewTheWidgetWillShowYourSelected,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            if (_pinSupported == false)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(l10n.uiTouchAndHoldAnEmptyAreaOnYour,
                      style: theme.textTheme.bodyMedium)),
            if (_message != null) ...[
              Text(_message!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
                label: _pinSupported == false
                    ? l10n.uiGotIt
                    : l10n.uiAddToHomeScreen,
                icon: Icons.add_to_home_screen_rounded,
                onPressed: _busy || _pinSupported == null
                    ? null
                    : _pinSupported == false
                        ? () => Navigator.pop(context)
                        : _add),
          ]),
    );
  }
}
