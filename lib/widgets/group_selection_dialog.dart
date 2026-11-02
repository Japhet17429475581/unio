import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../utils/user_messages.dart';
import 'group_picker.dart';

/// Uses the same directory, suggestions and validation as sign-in.
class GroupSelectionDialog extends StatefulWidget {
  final String group;
  final Future<void> Function(String) onSave;
  const GroupSelectionDialog(
      {super.key, required this.group, required this.onSave});
  @override
  State<GroupSelectionDialog> createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<GroupSelectionDialog> {
  late final _controller = TextEditingController(text: widget.group);
  final _picker = GlobalKey<GroupPickerState>();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final group = await _picker.currentState!.validate();
      await widget.onSave(group);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted)
        setState(() {
          _error = userMessage(error);
          _busy = false;
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return PopScope(
        canPop: !_busy,
        child: AlertDialog(
            title: Text(l10n.uiChangeGroup),
            content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      GroupPicker(
                          key: _picker,
                          controller: _controller,
                          enabled: !_busy,
                          portal: false,
                          onChanged: () {},
                          onSubmit: _save),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))
                      ],
                      if (_busy) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator()
                      ]
                    ]))),
            actions: [
              TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(l10n.uiCancel)),
              FilledButton(
                  onPressed: _busy ? null : _save, child: Text(l10n.uiSave))
            ]));
  }
}
