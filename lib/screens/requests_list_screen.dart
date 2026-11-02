import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/material.dart';

import '../widgets/unio_loader.dart';
import '../models/portal_request.dart';
import '../services/requests_service.dart';
import '../services/direct_portal_client.dart';
import '../services/request_status_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/message.dart';
import '../widgets/feature_header.dart';
import '../widgets/launch_list_entrance.dart';
import '../widgets/request_card.dart';
import 'request_form_screen.dart';

class RequestsListScreen extends StatefulWidget {
  const RequestsListScreen({super.key});
  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen>
    with WidgetsBindingObserver {
  RequestsListResult? _data;
  String? _error;
  String _errorTitle = l10n.uiPortalTemporarilyUnavailable;
  bool _loading = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.requests);
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<void> _reload() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await loadSession();
      final result = await fetchRequestsList();
      if (!mounted) return;
      setState(() => _data = result);
      if (session?.portalLogin != null) {
        try {
          await rememberRequestStatuses(
              result.requests, portalOwner(session!.portalLogin!));
        } catch (_) {}
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _error = userMessage(error);
          _errorTitle = error is DirectPortalException &&
                  error.code == 'requests_unrecognized_page'
              ? l10n.uiCheckYourVgspuPortalAccount
              : l10n.uiCouldNotLoadApplications;
        });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(RequestListItem item) async {
    if (!item.canFill) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(item.isNew
              ? RequestListItem.waitingMessage
              : l10n.uiApplicationStatusEditingIsCurrentlyUnavailable(
                  (item.displayStatus).toString()))));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RequestFormScreen(requestId: item.id)));
    if (mounted) await _reload();
  }

  Future<void> _create() async {
    final data = _data;
    if (data == null || _creating) return;
    final picked = await showModalBottomSheet<(RequestOption, RequestOption)>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _NewRequestSheet(categories: data.availableCategories));
    if (picked == null || !mounted) return;
    setState(() => _creating = true);
    analytics.track(AnalyticsEvent.requestCreate,
        outcome: AnalyticsOutcome.attempt);
    try {
      final id =
          await createRequest(categoryId: picked.$1.id, typeId: picked.$2.id);
      analytics.track(AnalyticsEvent.requestCreate,
          outcome: AnalyticsOutcome.success);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      final item = _data?.requests.where((r) => r.id == id).firstOrNull;
      if (item?.canFill == true) {
        await _open(item!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(l10n.uiApplicationCreatedThePortalIsPreparingTheForm)));
      }
    } catch (error) {
      analytics.track(AnalyticsEvent.requestCreate,
          outcome: AnalyticsOutcome.unconfirmed);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userMessage(error))));
        await _reload();
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uiCertificatesAndApplications), actions: [
        IconButton(
            tooltip: l10n.uiRefreshStatuses,
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded)),
      ]),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _creating || data.availableCategories.isEmpty
                  ? null
                  : _create,
              icon: _creating
                  ? const SizedBox(width: 20, height: 20, child: UnioLoader())
                  : const Icon(Icons.add_rounded),
              label: Text(_creating
                  ? l10n.uiCreatingApplication
                  : l10n.uiSubmitAnApplication)),
      body: SafeArea(
          child: data == null
              ? _error != null
                  ? Message(
                      icon: Icons.cloud_off_rounded,
                      title: _errorTitle,
                      text: _error!,
                      actionLabel: l10n.uiTryAgain,
                      onAction: _reload)
                  : const Center(child: UnioLoader())
              : UnioRefreshIndicator(
                  onRefresh: _reload,
                  child: LaunchListEntrance(
                      ready: data.requests.isNotEmpty,
                      contentKey: data.requests,
                      child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(l10n.uiMyApplications,
                                      style: theme.textTheme.titleLarge)),
                              Text('${data.requests.length}',
                                  style: theme.textTheme.titleMedium)
                            ]),
                            const SizedBox(height: 6),
                            Text(
                                l10n.uiCheckedAtPullDownToRefresh(
                                    (TimeOfDay.fromDateTime(data.checkedAt)
                                            .format(context))
                                        .toString()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            if (_loading)
                              const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: LinearProgressIndicator(minHeight: 2)),
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                      l10n.uiCouldNotRefreshStatusesShowingPreviousData(
                                          (_error).toString()),
                                      style: TextStyle(
                                          color: theme.colorScheme.error))),
                            const SizedBox(height: 16),
                            if (data.requests.isEmpty)
                              Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Message(
                                      icon: Icons.inbox_outlined,
                                      title: l10n.uiNoApplicationsYet,
                                      text: l10n
                                          .uiChooseTheDocumentYouNeedUsingTheButton)),
                            for (var index = 0;
                                index < data.requests.length;
                                index++)
                              LaunchListItem(
                                  key: ValueKey(
                                      'request-entrance-${data.requests[index].id}'),
                                  index: index,
                                  child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: RequestCard(
                                          item: data.requests[index],
                                          onTap: () =>
                                              _open(data.requests[index])))),
                          ])))),
    );
  }
}

class _NewRequestSheet extends StatefulWidget {
  final List<RequestOption> categories;
  const _NewRequestSheet({required this.categories});
  @override
  State<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<_NewRequestSheet> {
  RequestOption? _category;
  RequestOption? _type;
  List<RequestOption> _types = [];
  bool _loading = false;
  String? _error;
  int _generation = 0;

  Future<void> _select(RequestOption? category) async {
    final generation = ++_generation;
    setState(() {
      _category = category;
      _type = null;
      _types = [];
      _error = null;
      _loading = category != null;
    });
    if (category == null) return;
    try {
      final types = await fetchRequestTypes(category.id);
      if (mounted && generation == _generation) setState(() => _types = types);
    } catch (error) {
      if (mounted && generation == _generation)
        setState(() => _error = userMessage(error));
    } finally {
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FeatureHeader(
                      compact: true,
                      eyebrow: l10n.uiNewApplication,
                      title: l10n.uiWhichDocumentDoYouNeed,
                      icon: Icons.note_add_outlined,
                      description:
                          l10n.uiChooseACategoryAndApplicationTypeFromThe),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<RequestOption>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.uiCategory),
                      items: [
                        for (final c in widget.categories)
                          DropdownMenuItem(
                              value: c,
                              child:
                                  Text(c.name, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: _select),
                  const SizedBox(height: 16),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null) ...[
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    TextButton(
                        onPressed: () => _select(_category),
                        child: Text(l10n.uiRetryLoading))
                  ],
                  if (!_loading &&
                      _category != null &&
                      _error == null &&
                      _types.isEmpty)
                    Text(l10n.uiNoApplicationsAvailableInThisCategory),
                  DropdownButtonFormField<RequestOption>(
                      key: ValueKey('types-$_generation'),
                      isExpanded: true,
                      decoration:
                          InputDecoration(labelText: l10n.uiApplicationType),
                      items: [
                        for (final t in _types)
                          DropdownMenuItem(
                              value: t,
                              child: Text(t.name,
                                  maxLines: 2, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: _loading || _types.isEmpty
                          ? null
                          : (value) => setState(() => _type = value)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                      onPressed: _category == null || _type == null || _loading
                          ? null
                          : () => Navigator.pop(context, (_category!, _type!)),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.uiCreateApplication)),
                  const SizedBox(height: 8),
                  Text(l10n.uiADraftWillBeCreatedOnThePortal,
                      textAlign: TextAlign.center)
                ])));
  }
}
