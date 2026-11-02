import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/legal_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/signature_surface.dart';
import '../widgets/unio_card.dart';

/// A single screen serves both first acceptance and subsequent review/revocation.
class LegalDocumentsScreen extends StatefulWidget {
  final Future<void> Function()? onDecline;
  final bool requireAcceptance;
  final Future<void> Function()? onAccepted;
  final Future<void> Function()? onDelete;
  const LegalDocumentsScreen(
      {super.key,
      this.requireAcceptance = false,
      this.onAccepted,
      this.onDelete,
      this.onDecline});
  @override
  State<LegalDocumentsScreen> createState() => _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends State<LegalDocumentsScreen> {
  Map<String, LegalDocument>? _docs;
  final Map<String, Map<String, dynamic>?> _receipts = {};
  bool _terms = false, _personal = false, _analytics = false, _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final docs = await legal.documents();
      for (final id in docs.keys) {
        _receipts[id] = await legal.latest(id);
      }
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _analytics = !widget.requireAcceptance &&
            _receipts['analytics']?['accepted'] == true;
      });
    } catch (_) {
      if (mounted)
        setState(
            () => _message = l10n.uiCouldNotReadTheDocumentsPleaseReopenThis);
    }
  }

  Future<void> _analyticsChanged(bool value) async {
    if (widget.requireAcceptance) {
      setState(() => _analytics = value);
      return;
    }
    setState(() => _busy = true);
    try {
      await legal.setAnalytics(value);
      final token = (await loadSession())?.accountToken;
      var pending = false;
      if (token != null) {
        try {
          await legal.sync(token);
        } catch (_) {
          pending = true;
        }
      }
      if (mounted)
        setState(() {
          _analytics = value;
          _message = value
              ? l10n.uiYourChoiceHasBeenSaved
              : l10n.uiAnalyticsIsOffPreviouslySharedDataIsNot;
          if (pending)
            _message = l10n
                .uiTheServerRecordWillBeSentAgainWhen((_message!).toString());
        });
      await _load();
    } catch (_) {
      if (mounted)
        setState(
            () => _message = l10n.uiCouldNotCompleteTheChangePleaseTryAgain);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await legal.acceptCore();
      await legal.setAnalytics(_analytics);
      final token = (await loadSession())?.accountToken;
      if (token != null) {
        try {
          await legal.sync(token);
        } catch (_) {/* retried at resume */}
      }
      if (widget.onAccepted != null) {
        await widget.onAccepted!();
      } else if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted)
        setState(() => _message = l10n.uiCouldNotSaveYourChoicePleaseTryAgain);
      // A partial save must not let a later login bypass the failed decision.
      try {
        await legalStorage.write(key: legalActiveKey, value: 'false');
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(l10n.uiDeleteAccountAndData),
              content: SingleChildScrollView(
                  child:
                      Text(l10n.uiThisDeletesYourUnioServerAccountLocalSign)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.uiCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.uiDelete))
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onDelete?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.uiDocumentsAndData)),
        body: SignatureBackdrop(
            child: Material(
                type: MaterialType.transparency,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(
                      widget.requireAcceptance
                          ? l10n.uiYourChoices
                          : l10n.uiDataManagement,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(l10n.uiAnalyticsIsOptionalDecliningDoesNotLimitUnio),
                  if (appLocale.locale.languageCode == 'en') ...[
                    const SizedBox(height: 8),
                    Text(l10n.documentsOriginalLanguage,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 16),
                  if (_docs == null && _message == null)
                    const LinearProgressIndicator(),
                  for (final doc in _docs?.values ?? <LegalDocument>[]) ...[
                    UnioCard(
                        child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(doc.title),
                            subtitle: Text(
                                '${doc.draft ? '${l10n.draft} · ' : ''}${doc.version}${_receipts[doc.id] == null ? '' : '\n${_receipts[doc.id]!['accepted'] == true ? l10n.accepted : l10n.withdrawn}: ${_receipts[doc.id]!['occurred_at']}'}'),
                            children: [SelectableText(doc.text)])),
                    const SizedBox(height: 12)
                  ],
                  if (widget.requireAcceptance && _docs != null) ...[
                    CheckboxListTile(
                        key: const Key('accept-terms'),
                        contentPadding: EdgeInsets.zero,
                        value: _terms,
                        onChanged:
                            _busy ? null : (v) => setState(() => _terms = v!),
                        title: Text(l10n.uiIAcceptTheUserAgreement)),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _personal,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _personal = v!),
                        title:
                            Text(l10n.uiIConsentToUnioProcessingMyPersonalData),
                        subtitle:
                            Text(l10n.uiSeparateConsentThePolicyAndFullTextAre))
                  ],
                  if (kIsWeb)
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(l10n.uiMytrackerIsNotUsedInTheWebApp)),
                  if (_docs != null && !kIsWeb)
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _analytics,
                        onChanged: _busy ? null : _analyticsChanged,
                        title: Text(l10n.uiIGiveSeparateConsentToMytracker),
                        subtitle: Text(
                            l10n.uiOptionalYouCanWithdrawConsentHereAtAny)),
                  if (_message != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_message!)),
                  if (widget.requireAcceptance)
                    FilledButton(
                        onPressed:
                            !_terms || !_personal || _busy ? null : _accept,
                        child: Text(_busy ? l10n.uiSaving : l10n.uiContinue)),
                  if (widget.requireAcceptance && widget.onDecline != null)
                    TextButton(
                        onPressed: _busy ? null : widget.onDecline,
                        child: Text(l10n.uiSignOutWithoutAccepting)),
                  if (!widget.requireAcceptance && widget.onDelete != null) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.uiWithdrawConsentAndDeleteData))
                  ],
                  const SizedBox(height: 16),
                  Text(l10n.uiNotesAreKeptUntilYouDeleteThemInactive)
                ]))));
  }
}
