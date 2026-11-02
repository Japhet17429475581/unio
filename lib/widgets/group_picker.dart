import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../services/groups_service.dart';

/// Inline suggestions also fit small screens and move with the login form.
class GroupPicker extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool portal;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final Future<List<String>> Function() load;
  const GroupPicker(
      {super.key,
      required this.controller,
      required this.enabled,
      required this.portal,
      required this.onChanged,
      required this.onSubmit,
      this.load = fetchGroups});
  @override
  State<GroupPicker> createState() => GroupPickerState();
}

class GroupPickerState extends State<GroupPicker> {
  final _focus = FocusNode();
  List<String>? _groups;
  String? _error;
  bool _loading = false;
  Future<void>? _pending;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
    _load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() {
    if (_loading) return _pending!;
    setState(() {
      _loading = true;
      _error = null;
    });
    return _pending = () async {
      try {
        final groups = await widget.load();
        if (mounted) setState(() => _groups = groups);
      } catch (_) {
        if (mounted)
          setState(() => _error = l10n.uiGroupListCurrentlyUnavailable);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }();
  }

  Future<String> validate() async {
    if (_loading) await _pending;
    if (_groups == null) await _load();
    if (_groups == null) {
      throw GroupDirectoryException(l10n.uiCouldNotCheckTheGroupListPleaseTry);
    }
    return resolveGroup(_groups!, widget.controller.text);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final matches = searchGroups(_groups ?? [], widget.controller.text);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: widget.controller,
        focusNode: _focus,
        enabled: widget.enabled,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        textInputAction:
            widget.portal ? TextInputAction.next : TextInputAction.done,
        onSubmitted: widget.portal
            ? (_) => _focus.nextFocus()
            : (_) => widget.onSubmit(),
        onChanged: (_) {
          widget.onChanged();
          setState(() {});
        },
        decoration: InputDecoration(
            labelText: l10n.uiGroupCode,
            hintText: l10n.uiStartTypingAGroupCodeOrNumber,
            prefixIcon: Icon(Icons.groups_outlined)),
      ),
      if (_loading)
        Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(l10n.uiLoadingGroups)),
      if (_error != null)
        TextButton.icon(
            onPressed: widget.enabled ? _load : null,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.uiTryAgain340((_error).toString()))),
      if (_focus.hasFocus && widget.enabled && _groups != null) ...[
        const SizedBox(height: 8),
        if (matches.isEmpty) Text(l10n.uiGroupNotFoundCheckTheCodeOrEnter),
        for (final group in matches)
          ListTile(
            dense: true,
            title: Text(group),
            trailing: const Icon(Icons.north_west_rounded, size: 18),
            onTap: () {
              widget.controller.text = group;
              widget.controller.selection =
                  TextSelection.collapsed(offset: group.length);
              widget.onChanged();
              _focus.unfocus();
              setState(() {});
            },
          ),
      ],
    ]);
  }
}
