import '../services/locale_service.dart';
import '../services/analytics_service.dart';
import '../utils/user_messages.dart';
import 'package:flutter/material.dart';
import '../widgets/feature_header.dart';
import '../widgets/unio_card.dart';

import '../widgets/unio_loader.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/portal_request.dart';
import '../services/direct_portal_client.dart';
import '../services/requests_service.dart';
import '../services/request_templates_service.dart';
import '../widgets/message.dart';

class RequestFormScreen extends StatefulWidget {
  final String requestId;
  const RequestFormScreen({super.key, required this.requestId});
  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  late Future<RequestForm> _future;
  final _formKey = GlobalKey<FormState>();
  final _values = <String, dynamic>{};
  final _controllers = <String, TextEditingController>{};
  final _files = <String, RequestFile>{};
  bool _pickingFile = false;
  bool _savingTemplate = false;
  bool _submitting = false;
  bool _attempted = false;
  SubmitResult? _result;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.requestForm);
    _future = fetchRequestForm(widget.requestId);
  }

  Future<void> _openPortal([String? path]) async {
    final uri = DirectPortalClient.checkedUri(
        path ?? '/request/${widget.requestId}/edit');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.uiCouldNotOpenTheBrowser)));
    }
  }

  Future<void> _saveTemplate(RequestTemplate template) async {
    if (_savingTemplate) return;
    setState(() => _savingTemplate = true);
    try {
      final saved = await saveRequestTemplate(template);
      if (saved) analytics.track(AnalyticsEvent.templateSaved);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.uiTemplateSavedFillItOutInADocument),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.uiCouldNotSaveTheTemplateTryAgainAnd),
        ));
      }
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  Future<void> _pickFile(
      RequestAttachment attachment, FormFieldState<RequestFile> state) async {
    if (_pickingFile) return;
    setState(() => _pickingFile = true);
    try {
      final file = await openFile(acceptedTypeGroups: [
        XTypeGroup(
          label: l10n.uiApplication,
          extensions: attachment.extensions,
          uniformTypeIdentifiers: const ['public.data'],
        )
      ]);
      if (file == null || !mounted) return;
      if (!attachment.extensions
          .contains(file.name.split('.').last.toLowerCase())) {
        throw DirectPortalException(l10n.uiChooseAFileInOneOfTheListed);
      }
      if (await file.length() > 20 * 1024 * 1024) {
        throw DirectPortalException(l10n.uiChooseAFileUpToMb);
      }
      final selected =
          RequestFile(name: file.name, bytes: await file.readAsBytes());
      if (selected.bytes.isEmpty)
        throw DirectPortalException(l10n.uiTheSelectedFileIsEmpty);
      if (!mounted || !state.mounted) return;
      setState(() => _files[attachment.fieldId] = selected);
      state.didChange(selected);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is DirectPortalException
                ? error.message
                : l10n.uiCouldNotReadTheFilePleaseSelectIt)));
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  Widget _attachment(RequestAttachment attachment) => FormField<RequestFile>(
        initialValue: _files[attachment.fieldId],
        validator: (file) =>
            attachment.required && !attachment.uploaded && file == null
                ? l10n.uiAttachYourApplication
                : null,
        builder: (state) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${attachment.label}${attachment.required ? ' *' : ''}',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(state.value?.name ??
                (attachment.uploaded
                    ? l10n.uiFileAlreadyUploadedToThePortal
                    : attachment.fieldId == '37'
                        ? l10n.uiAttachADocumentConfirmingYourSelectedCategory
                        : l10n.uiFillOutTheTemplateAndAttachYourApplication)),
            const SizedBox(height: 8),
            Text(
                l10n.uiUpToMb((attachment.extensions.join(', ').toUpperCase())
                    .toString()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed:
                    _pickingFile ? null : () => _pickFile(attachment, state),
                icon: const Icon(Icons.attach_file),
                label: Text(state.value == null
                    ? l10n.uiChooseFile
                    : l10n.uiReplaceFile)),
            if (state.value != null) ...[
              const SizedBox(height: 12),
              Text(l10n.uiTheFileWillBeUploadedWhenYouSubmit),
              TextButton(
                  onPressed: () {
                    setState(() => _files.remove(attachment.fieldId));
                    state.didChange(null);
                  },
                  child: Text(l10n.uiRemoveSelectedFile)),
            ],
            if (state.hasError)
              Text(state.errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      );

  Future<void> _submit(RequestForm form) async {
    if (_submitting ||
        _attempted ||
        _pickingFile ||
        !_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(l10n.uiSubmitApplication),
                content: Text(
                    l10n.uiCheckYourDetailsAndAttachmentsYourApplicationWill),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.uiReviewAgain)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.uiSubmit))
                ]));
    if (confirmed != true || !mounted) return;
    analytics.track(AnalyticsEvent.requestSubmit,
        outcome: AnalyticsOutcome.attempt);
    setState(() {
      _submitting = true;
      _attempted = true;
    });
    try {
      final result = await submitRequestForm(
          requestId: widget.requestId, values: _values, files: _files);
      analytics.track(AnalyticsEvent.requestSubmit,
          outcome: result.success
              ? AnalyticsOutcome.success
              : AnalyticsOutcome.rejected);
      if (mounted)
        setState(() {
          _result = result;
          if (result.errors.isNotEmpty) _attempted = false;
        });
    } on RequestNotFillableException catch (error) {
      analytics.track(AnalyticsEvent.requestSubmit,
          outcome: AnalyticsOutcome.rejected);
      if (mounted)
        setState(() =>
            _result = SubmitResult(success: false, message: error.message));
    } catch (_) {
      if (mounted)
        setState(() => _result = SubmitResult(
            // A timeout doesn't prove that the portal rejected the submission.
            success: false,
            message: l10n.uiSubmissionCouldNotBeConfirmedCheckTheApplication));
      analytics.track(AnalyticsEvent.requestSubmit,
          outcome: AnalyticsOutcome.unconfirmed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _field(RequestField field, RequestForm form) {
    _values.putIfAbsent(field.name, () => field.value);
    if (field.type == 'hidden') return const SizedBox.shrink();
    final income = form.fields.any((f) => f.name == 'field_143');
    final deliveryName = income ? 'field_143' : 'field_33';
    final delivery =
        form.fields.where((f) => f.name == deliveryName).firstOrNull;
    final isAddress = field.name == (income ? 'field_146' : 'field_34') &&
        delivery?.type == 'select';
    final deliveryValue = '${_values[deliveryName] ?? delivery?.value ?? ''}';
    final isEmail = isAddress && !income && deliveryValue == '2';
    final isDate = income && ['field_144', 'field_145'].contains(field.name);
    final isQuantity = income && field.name == 'field_166';
    if (isAddress && deliveryValue == '1') {
      _values[field.name] = '';
      _controllers[field.name]?.clear();
      return const SizedBox.shrink();
    }
    final label = isAddress
        ? (isEmail ? l10n.uiEmailAddress : l10n.uiPostalAddress)
        : isDate
            ? (field.name == 'field_144'
                ? l10n.uiStartOfPeriod
                : l10n.uiEndOfPeriod)
            : isQuantity
                ? l10n.uiNumberOfCopies
                : field.label;
    final required = field.required ||
        (isAddress && (deliveryValue == '2' || deliveryValue == '3'));
    final decoration = InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        errorMaxLines: 4,
        alignLabelWithHint: true,
        hintText: isDate ? l10n.uiDdMmYyyy : null,
        suffixIcon: isDate
            ? IconButton(
                icon: const Icon(Icons.calendar_month),
                tooltip: l10n.uiChooseDate,
                onPressed: () async {
                  final current =
                      parseRequestDate('${_values[field.name] ?? ''}') ??
                          DateTime.now();
                  final date = await showDatePicker(
                      context: context,
                      initialDate: current.year >= 1900 && current.year <= 2100
                          ? current
                          : DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100, 12, 31));
                  if (date != null && mounted)
                    setState(() {
                      _values[field.name] =
                          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                      _controllers[field.name]?.text = '${_values[field.name]}';
                    });
                })
            : null);
    String? validate(String? value) =>
        validateRequestValue(field, form, {..._values, field.name: value});

    Widget input;
    if (field.type == 'select') {
      final options = field.options ?? [];
      final current = '${_values[field.name] ?? ''}';
      input = DropdownButtonFormField<String>(
          key: ValueKey('request-select-${field.name}'),
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          dropdownColor: Theme.of(context).colorScheme.surface,
          initialValue: options.any((o) => o.id == current) ? current : null,
          decoration: decoration,
          // Menu rows need touch padding; the collapsed field has a dense height.
          // Reusing padded menu children clips the selected text completely.
          selectedItemBuilder: (context) => [
                for (final option in options)
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(option.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface))),
              ],
          items: [
            for (final option in options)
              DropdownMenuItem(
                  value: option.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(option.name),
                  ))
          ],
          validator: validate,
          onChanged: (value) => setState(() => _values[field.name] = value));
    } else if (field.type == 'checkbox') {
      input = FormField<bool>(
          initialValue: _values[field.name] == true,
          validator: (value) => required && value != true
              ? l10n.uiPleaseConfirmYourConsent
              : null,
          builder: (state) => Column(children: [
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    value: state.value,
                    onChanged: (v) {
                      state.didChange(v);
                      _values[field.name] = v;
                    }),
                if (state.hasError)
                  Text(state.errorText!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error))
              ]));
    } else {
      input = TextFormField(
          key: ValueKey('request-input-${field.name}'),
          controller: _controllers.putIfAbsent(
              field.name,
              () =>
                  TextEditingController(text: '${_values[field.name] ?? ''}')),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          cursorColor: Theme.of(context).colorScheme.primary,
          decoration: decoration,
          keyboardType: isEmail || field.type == 'email'
              ? TextInputType.emailAddress
              : field.type == 'number' || isQuantity
                  ? TextInputType.number
                  : isDate
                      ? TextInputType.datetime
                      : TextInputType.multiline,
          minLines: field.type == 'textarea' && !isAddress ? 2 : 1,
          maxLines: field.type == 'textarea' && !isAddress ? 4 : 2,
          validator: validate,
          onChanged: (value) => _values[field.name] = value);
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          input,
          if (field.hint.isNotEmpty && field.hint.trim() != label.trim())
            Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(field.hint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
        appBar: AppBar(
            title: Text(l10n.uiApplication160((widget.requestId).toString()))),
        body: SafeArea(
            child: FutureBuilder<RequestForm>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done)
                    return const Center(child: UnioLoader());
                  if (snapshot.hasError)
                    return Message(
                        icon: Icons.cloud_off_rounded,
                        title: snapshot.error is RequestNotFillableException
                            ? l10n.uiFormNotAvailableYet
                            : l10n.uiCouldNotOpenApplication,
                        text: userMessage(snapshot.error),
                        actionLabel:
                            snapshot.error is RequestNotFillableException
                                ? l10n.uiBackToApplications
                                : l10n.uiTryAgain,
                        onAction: () {
                          if (snapshot.error is RequestNotFillableException) {
                            Navigator.pop(context);
                          } else {
                            setState(() =>
                                _future = fetchRequestForm(widget.requestId));
                          }
                        });
                  final form = snapshot.data!;
                  final template = templateForForm(form);
                  final theme = Theme.of(context);
                  return Form(
                      key: _formKey,
                      child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: [
                            FeatureHeader(
                                compact: true,
                                eyebrow: l10n.uiApplication160(
                                    (widget.requestId).toString()),
                                title: form.editable
                                    ? l10n.uiFillInYourDetails
                                    : l10n.uiApplicationOnThePortal,
                                icon: Icons.edit_document,
                                description: form.editable
                                    ? l10n
                                        .uiFieldsMarkedWithAnAsteriskAreRequiredYou
                                    : l10n
                                        .uiThisApplicationCannotBeEditedItsCurrentStatus),
                            const SizedBox(height: 20),
                            if (template != null)
                              OutlinedButton.icon(
                                  onPressed: _savingTemplate
                                      ? null
                                      : () => _saveTemplate(template),
                                  icon: const Icon(Icons.download_outlined),
                                  label: Text(_savingTemplate
                                      ? l10n.uiSaving168
                                      : l10n.uiDownloadWordTemplate))
                            else if (form.templateUrl != null)
                              OutlinedButton.icon(
                                  onPressed: () =>
                                      _openPortal(form.templateUrl),
                                  icon: const Icon(Icons.download_outlined),
                                  label: Text(l10n.uiOpenTemplateOnThePortal)),
                            if (template != null || form.templateUrl != null)
                              const SizedBox(height: 16),
                            if (form.notice.isNotEmpty) ...[
                              Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: .08),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(form.notice))
                                      ])),
                              const SizedBox(height: 20)
                            ],
                            if (form.hasUnsupportedFields)
                              Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Text(l10n
                                      .uiSomeAttachmentsOrFieldsInThisFormAre)),
                            if (form.editable && !form.hasUnsupportedFields)
                              DecoratedBox(
                                  decoration: unioCardDecoration(context),
                                  child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 24, 16, 4),
                                      child: AbsorbPointer(
                                          absorbing: _submitting || _attempted,
                                          child: Column(children: [
                                            for (final field in form.fields)
                                              _field(field, form),
                                            for (final attachment
                                                in form.attachments)
                                              _attachment(attachment)
                                          ])))),
                            if (_result != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                            _result!.success
                                                ? Icons.task_alt_rounded
                                                : Icons.info_outline,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(height: 8),
                                        Text(
                                            _result!.success
                                                ? _result!.message
                                                : readableMessage(
                                                    _result!.message),
                                            style: theme.textTheme.titleMedium),
                                        for (final error in _result!.errors)
                                          Text(readableMessage(error),
                                              style: TextStyle(
                                                  color:
                                                      theme.colorScheme.error))
                                      ])),
                            const SizedBox(height: 20),
                            if (form.editable &&
                                !form.hasUnsupportedFields &&
                                !_attempted)
                              FilledButton.icon(
                                  onPressed: _submitting || _pickingFile
                                      ? null
                                      : () => _submit(form),
                                  icon: const Icon(Icons.send_rounded),
                                  label: Text(l10n.uiSubmitForProcessing)),
                            if (_submitting) const Center(child: UnioLoader()),
                            if (_attempted && !_submitting)
                              FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(l10n.uiCheckApplicationStatus)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                                onPressed:
                                    _submitting ? null : () => _openPortal(),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: Text(l10n.uiOpenOnTheVgspuPortal))
                          ]));
                })));
  }
}
