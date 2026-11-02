import 'locale_service.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import '../models/portal_request.dart';
import 'direct_portal_client.dart';
import 'portal_diagnostics.dart';

typedef RequestsApiException = DirectPortalException;

class RequestsListResult {
  final List<RequestListItem> requests;
  final List<RequestOption> availableCategories;
  final List<RequestOption> availableTypes;
  final DateTime checkedAt;
  RequestsListResult(
      {required this.requests,
      required this.availableCategories,
      this.availableTypes = const [],
      DateTime? checkedAt})
      : checkedAt = checkedAt ?? DateTime.now();
}

bool isObsoleteRequest(String name) =>
    RegExp(r'covid|ковид|коронавирус', caseSensitive: false).hasMatch(name);

bool isUnavailableRequestType(String name) => isObsoleteRequest(name);

List<RequestOption> _options(Element? select, {bool includeEmpty = false}) => [
      for (final option in select?.querySelectorAll('option') ?? <Element>[])
        if ((includeEmpty || (option.attributes['value'] ?? '').isNotEmpty) &&
            !isObsoleteRequest(option.text))
          RequestOption(
              id: option.attributes['value']!, name: portalText(option.text)),
    ];

RequestsListResult parseRequestsList(String source) {
  if (source.trim().isEmpty) {
    throw DirectPortalException(
        'Портал вернул пустой ответ. Попробуйте обновить список. Код REQ_EMPTY.',
        code: 'requests_empty_response');
  }
  final doc = html.parse(source);
  DirectPortalClient.requireSession(doc);
  final categorySelector = doc.querySelector(
      '#category-selector, select[name="category_id"], select[name="Request[category_id]"]');
  final editLinks = doc.querySelectorAll('a[href]').where((link) {
    try {
      return RegExp(r'^/request/\d+/edit/?$').hasMatch(
          DirectPortalClient.checkedUri(link.attributes['href']!).path);
    } on DirectPortalException {
      return false;
    }
  }).toList();
  final heading = doc
      .querySelectorAll('h1, h2, .page-title')
      .map((e) => portalText(e.text).toLowerCase())
      .join(' ');
  final empty = doc.querySelector('.empty');
  final explicitEmptyList = heading.contains('заявлен') &&
      empty != null &&
      RegExp(r'нет заявлен|заявлен.{0,20}нет|не найден|ничего не найден|найдено\s*0|no results|no requests',
              caseSensitive: false)
          .hasMatch(portalText(empty.text));
  final pageTitle = portalText(doc.querySelector('title')?.text).toLowerCase();
  if (doc.querySelector(
              '#challenge-form, #cf-challenge-running, script[src*="/cdn-cgi/challenge-platform/"]') !=
          null ||
      pageTitle.contains('just a moment') ||
      pageTitle == 'access denied') {
    throw DirectPortalException(
        'Портал ограничил доступ. Попробуйте другую сеть или откройте портал в браузере. Код REQ_ACCESS.',
        code: 'requests_access_challenge');
  }
  if (categorySelector == null &&
      doc.querySelector('.requestItem, .list-view') == null &&
      editLinks.isEmpty &&
      !explicitEmptyList) {
    throw DirectPortalException(
        'Портал вернул другую страницу вместо списка заявлений. '
        'Откройте личный кабинет ВГСПУ: возможно, там требуется действие. '
        'Если раздел доступен, сообщите поддержке код REQ_PAGE.',
        code: 'requests_unrecognized_page');
  }
  return RequestsListResult(
    availableCategories: _options(categorySelector),
    requests: [
      for (final item in doc.querySelectorAll('.requestItem'))
        RequestListItem(
          id: item.attributes['data-key'] ??
              RegExp(r'/request/(\d+)/edit')
                  .firstMatch(item
                          .querySelector('a[href*="/edit"]')
                          ?.attributes['href'] ??
                      '')
                  ?.group(1) ??
              '',
          title: portalText(item.querySelector('.requestItem-title')?.text),
          category: portalText(
              item.querySelector('.requestItem-Info-Descr h5')?.text),
          status: portalText(item.querySelector('.Ach-Status')?.text),
          updated: portalText(
              item.querySelector('.requestItem-Info-Descr-Status p')?.text),
          editUrl:
              item.querySelector('a.requestItem-Info')?.attributes['href'] ??
                  '',
        ),
      // Some portal layouts expose edit links without the requestItem wrapper.
      for (final link in editLinks.where((link) =>
          portalAncestor(link, (e) => e.classes.contains('requestItem')) ==
          null))
        RequestListItem(
          id: RegExp(r'/request/(\d+)/edit')
              .firstMatch(
                  DirectPortalClient.checkedUri(link.attributes['href']!).path)!
              .group(1)!,
          title: portalText(
              link.querySelector('.requestItem-title')?.text ?? link.text),
          category: '',
          status: '',
          updated: '',
          editUrl: link.attributes['href']!,
        ),
    ],
  );
}

Future<RequestsListResult> readRequestsList(DirectPortalClient client) async {
  final response = await client.request('/request/index');
  final first = _parseListResponse(response);
  var document = html.parse(response.data);
  final requests = {for (final item in first.requests) item.id: item};
  final seen = <String>{};
  for (var page = 0; page < 20; page++) {
    final next = document
        .querySelector('a[rel=next], .pagination .next:not(.disabled) a')
        ?.attributes['href'];
    if (next == null || !seen.add(next)) {
      return RequestsListResult(
          requests: requests.values.toList(),
          availableCategories: first.availableCategories);
    }
    final result = await client.request(next);
    for (final item in _parseListResponse(result).requests) {
      requests[item.id] = item;
    }
    document = html.parse(result.data);
  }
  throw DirectPortalException(
      l10n.tooManyRequestPages);
}

RequestsListResult _parseListResponse(Response<String> response) {
  try {
    return parseRequestsList(response.data ?? '');
  } on DirectPortalException catch (error) {
    throw DirectPortalException(error.message,
        code: error.code, statusCode: response.statusCode);
  }
}

Future<RequestsListResult> fetchRequestsList() => withPortal((client) async {
      try {
        return await readRequestsList(client);
      } on DirectPortalException catch (error) {
        if (client.diagnosticsEnabled)
          unawaited(portalDiagnostics.report(error));
        rethrow;
      }
    }, retryReadOnly: true);

Future<List<RequestOption>> readRequestTypes(
    DirectPortalClient client, String categoryId) async {
  final response = await client.request(
      '/request/get-types?${Uri(queryParameters: {
            'category_id': categoryId
          }).query}',
      ajax: true);
  final dynamic data;
  try {
    data = jsonDecode(response.data ?? '');
  } catch (_) {
    throw DirectPortalException(
        l10n.typesNotReturned);
  }
  if (data is! Map || data['result'] != 'ok')
    throw DirectPortalException(l10n.typesLoadFailed);
  final raw = data['items'];
  final values = raw is Map
      ? raw.values
      : raw is List
          ? raw
          : const [];
  return [
    for (final item in values)
      if (item is Map &&
          item['id'] != null &&
          !isUnavailableRequestType('${item['text']}'))
        RequestOption(id: '${item['id']}', name: '${item['text'] ?? ''}')
  ];
}

Future<List<RequestOption>> fetchRequestTypes(String categoryId) =>
    withPortal((client) => readRequestTypes(client, categoryId));

String _requestPath(String id) {
  if (!RegExp(r'^\d+$').hasMatch(id))
    throw DirectPortalException(l10n.invalidRequestId);
  return '/request/$id/edit';
}

RequestForm parseRequestForm(String source, String requestId) {
  final doc = html.parse(source);
  DirectPortalClient.requireSession(doc);
  final form = doc.querySelector('#approve-request-form');
  final action = form?.attributes['action'];
  final fields = <RequestField>[];
  var unsupported = false;
  final attachments = <RequestAttachment>[];
  for (final input in doc.querySelectorAll('input[type=file]')) {
    final variable = input.attributes['data-krajee-fileinput'];
    final name = input.attributes['name'];
    final scripts =
        doc.querySelectorAll('script').map((e) => e.text).join('\n');
    final match = variable == null
        ? null
        : RegExp('window\\.${RegExp.escape(variable)}\\s*=\\s*(\\{.*?\\})\\s*;',
                dotAll: true)
            .firstMatch(scripts);
    try {
      final config = jsonDecode(match?.group(1) ?? '') as Map<String, dynamic>;
      final fieldId = '${(config['uploadExtraData'] as Map)['field_id']}';
      final uri = DirectPortalClient.checkedUri(config['uploadUrl'] as String);
      final extensions = (config['allowedFileExtensions'] as List)
          .cast<String>()
          .map((e) => e.toLowerCase())
          .toList();
      if (name == null ||
          name.isEmpty ||
          !RegExp(r'^\d+$').hasMatch(fieldId) ||
          uri.path != '/request/$requestId/upload' ||
          uri.hasQuery ||
          extensions.isEmpty) {
        unsupported = true;
        continue;
      }
      final container =
          portalAncestor(input, (e) => e.classes.contains('uploader-item'));
      attachments.add(RequestAttachment(
          fieldId: fieldId,
          inputName: name,
          label: portalText(container?.querySelector('h2')?.text).replaceAll(
              RegExp(r'\s*\(обязателен[^)]*\)', caseSensitive: false), ''),
          uploadUrl: uri.toString(),
          extensions: extensions,
          required: config['required'] == true,
          uploaded:
              container?.text.toLowerCase().contains('файл уже загружен') ==
                  true));
    } catch (_) {
      // Unknown file controls must not silently produce a partial submission.
      unsupported = true;
    }
  }
  for (final input in doc.querySelectorAll('[data-transfer="1"][name]')) {
    final container = portalAncestor(
            input,
            (e) => e.classes.any({
                  'list-item',
                  'text-item',
                  'string-item',
                  'uploader-item'
                }.contains)) ??
        input.parent;
    final heading = portalText(container?.querySelector('h2, label')?.text);
    final label = heading.replaceAll(
        RegExp(r'\s*\(обязателен[^)]*\)', caseSensitive: false), '');
    final type = input.localName == 'input'
        ? input.attributes['type'] ?? 'text'
        : input.localName ?? 'text';
    if (![
      'text',
      'email',
      'tel',
      'number',
      'date',
      'textarea',
      'select',
      'checkbox',
      'hidden'
    ].contains(type)) unsupported = true;
    final options =
        type == 'select' ? _options(input, includeEmpty: true) : null;
    fields.add(RequestField(
      name: input.attributes['name']!,
      label: label.isEmpty ? input.attributes['name']! : label,
      hint: portalText(container?.querySelector('h3, .hint-block')?.text),
      type: type,
      required: input.attributes.containsKey('required') ||
          heading.toLowerCase().contains('обязател'),
      value: type == 'select'
          ? input.querySelector('option[selected]')?.attributes['value'] ??
              (options?.isNotEmpty == true ? options!.first.id : '')
          : type == 'textarea'
              ? input.text
              : type == 'checkbox'
                  ? input.attributes.containsKey('checked')
                  : input.attributes['value'] ?? '',
      options: options,
    ));
  }
  return RequestForm(
      action: DirectPortalClient.checkedUri(action == null || action.isEmpty
              ? _requestPath(requestId)
              : action)
          .toString(),
      method: 'POST',
      fields: fields,
      attachments: attachments,
      templateUrl:
          doc.querySelector('a[href\$="/request/$requestId/template"]') == null
              ? null
              : DirectPortalClient.checkedUri('/request/$requestId/template')
                  .toString(),
      hidden: {
        ...DirectPortalClient.hiddenFields(form),
        ...DirectPortalClient.csrfFields(doc)
      },
      notice: doc
          .querySelectorAll('.Cont > .text-item')
          .where((e) => e.querySelector('[data-transfer]') == null)
          .map((e) => portalText(e.text))
          .join('\n'),
      editable: form != null,
      hasUnsupportedFields: unsupported ||
          (form != null && fields.isEmpty && attachments.isEmpty));
}

Future<void> _requireFillable(
    DirectPortalClient client, String requestId) async {
  _requestPath(requestId);
  final list = await readRequestsList(client);
  final item = list.requests.where((r) => r.id == requestId).firstOrNull;
  if (item?.isNew == true)
    throw RequestNotFillableException(RequestListItem.waitingMessage);
  if (item?.canFill != true)
    throw RequestNotFillableException(
        l10n.formNotFillable);
}

class RequestNotFillableException extends DirectPortalException {
  const RequestNotFillableException(super.message);
}

Future<RequestForm> fetchRequestForm(String requestId) =>
    withPortal((client) async {
      await _requireFillable(client, requestId);
      final page = await client.request(_requestPath(requestId));
      return parseRequestForm(page.data ?? '', requestId);
    });

Future<String> createRequest(
        {required String categoryId, required String typeId}) =>
    withPortal((client) async {
      final page = await client.request('/request/index');
      final doc = html.parse(page.data);
      DirectPortalClient.requireSession(doc);
      final types = await readRequestTypes(client, categoryId);
      if (!types.any((type) => type.id == typeId))
        throw DirectPortalException(
            l10n.typeNoLongerAvailable);
      final response = await client.request('/request/create',
          fields: {
            ...DirectPortalClient.hiddenFields(
                doc.querySelector('form[action*="/request/create"]')),
            ...DirectPortalClient.csrfFields(doc),
            'CreateRequestForm[category_id]': categoryId,
            'CreateRequestForm[type_id]': typeId,
          },
          followRedirects: false);
      DirectPortalClient.requireSession(html.parse(response.data));
      final location = response.headers.value('location');
      final target = location == null
          ? response.realUri
          : DirectPortalClient.checkedUri(
              response.realUri.resolve(location).toString());
      final id =
          RegExp(r'/request/(\d+)/edit').firstMatch(target.path)?.group(1);
      if (id == null)
        throw DirectPortalException(
            l10n.draftNotConfirmed);
      return id;
    });

class SubmitResult {
  final bool success;
  final String message;
  final List<String> errors;
  const SubmitResult(
      {required this.success, required this.message, this.errors = const []});
}

class RequestFile {
  final String name;
  final Uint8List bytes;
  const RequestFile({required this.name, required this.bytes});
}

DateTime? parseRequestDate(String text) {
  final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(text.trim());
  if (match == null) return null;
  final day = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final year = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  return date.day == day && date.month == month && date.year == year
      ? date
      : null;
}

String? validateRequestValue(
    RequestField field, RequestForm form, Map<String, dynamic> values) {
  final text = '${values[field.name] ?? field.value ?? ''}'.trim();
  final income = form.fields.any((f) => f.name == 'field_143');
  final deliveryName = income ? 'field_143' : 'field_33';
  final delivery =
      '${values[deliveryName] ?? form.fields.where((f) => f.name == deliveryName).firstOrNull?.value ?? ''}';
  final address = field.name == (income ? 'field_146' : 'field_34');
  if (address && delivery == '1') return null;
  if ((field.required || (address && delivery != '1')) && text.isEmpty)
    return l10n.fieldRequired;
  if (address &&
      !income &&
      delivery == '2' &&
      text.isNotEmpty &&
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text))
    return l10n.emailInvalid;
  if (income &&
      ['field_144', 'field_145'].contains(field.name) &&
      text.isNotEmpty) {
    final date = parseRequestDate(text);
    if (date == null) return l10n.dateInvalid;
    final start = parseRequestDate('${values['field_144'] ?? ''}');
    if (field.name == 'field_145' && start != null && date.isBefore(start))
      return l10n.periodInvalid;
  }
  if (income &&
      field.name == 'field_166' &&
      text.isNotEmpty &&
      (!RegExp(r'^\d+$').hasMatch(text) || (int.tryParse(text) ?? 0) < 1))
    return l10n.positiveIntegerRequired;
  return null;
}

Future<SubmitResult> submitRequestForm(
        {required String requestId,
        required Map<String, dynamic> values,
        Map<String, RequestFile> files = const {}}) =>
    withPortal((client) async {
      await _requireFillable(client, requestId);
      final page = await client.request(_requestPath(requestId));
      final form = parseRequestForm(page.data ?? '', requestId);
      if (!form.editable || form.hasUnsupportedFields)
        throw DirectPortalException(
            l10n.formPortalOnly);
      final payload = {...form.hidden};
      for (final field in form.fields) {
        final value = values[field.name] ?? field.value ?? '';
        final text =
            value is bool ? (value ? '1' : '0') : value.toString().trim();
        final validation = validateRequestValue(field, form, values);
        if (validation != null)
          return SubmitResult(
              success: false,
              message: l10n.checkFields,
              errors: ['${field.label}: $validation']);
        if (field.options != null && !field.options!.any((o) => o.id == text))
          throw DirectPortalException(l10n.checkNamedField(field.label));
        payload[field.name] = text;
      }
      // Validate every attachment before sending any file or the final form.
      for (final attachment in form.attachments) {
        final file = files[attachment.fieldId];
        final missing =
            attachment.required && !attachment.uploaded && file == null;
        final invalid = file != null &&
            (file.bytes.isEmpty ||
                !attachment.extensions
                    .contains(file.name.split('.').last.toLowerCase()));
        if (missing || invalid)
          return SubmitResult(
              success: false,
              message: l10n.checkAttachments,
              errors: [
                missing
                    ? 'Прикрепите ${attachment.label.toLowerCase()}.'
                    : l10n.invalidNamedFile(attachment.label)
              ]);
      }
      for (final attachment in form.attachments) {
        final file = files[attachment.fieldId];
        if (file == null) continue;
        final upload = await client.request(attachment.uploadUrl,
            ajax: true,
            followRedirects: false,
            multipart: FormData.fromMap({
              ...form.hidden,
              'field_id': attachment.fieldId,
              attachment.inputName:
                  MultipartFile.fromBytes(file.bytes, filename: file.name)
            }));
        // Krajee fileinput treats a JSON response without `error` as accepted.
        dynamic uploaded;
        try {
          uploaded = jsonDecode(upload.data ?? '');
        } catch (_) {}
        if (upload.statusCode != 200 ||
            uploaded is! Map ||
            (uploaded['error'] != null &&
                uploaded['error'] != false &&
                '${uploaded['error']}'.isNotEmpty)) {
          return SubmitResult(
              success: false,
              message: l10n.fileRejected,
              errors: [
                l10n.checkAttachmentFormat
              ]);
        }
      }
      final response =
          await client.request(form.action, fields: payload, ajax: true);
      final doc = html.parse(response.data);
      DirectPortalClient.requireSession(doc);
      final errors = doc
          .querySelectorAll('.help-block, .error-summary, .alert-danger')
          .map((e) => portalText(e.text))
          .where((s) => s.isNotEmpty)
          .toList();
      if (errors.isNotEmpty)
        return SubmitResult(
            success: false,
            message: l10n.portalCorrectForm,
            errors: errors);
      // HTTP 200 alone is not proof of submission. Verify the portal's status.
      final list = await readRequestsList(client);
      final matches = list.requests.where((r) => r.id == requestId);
      if (matches.isNotEmpty &&
          matches.first.status.isNotEmpty &&
          !RegExp(r'получение информации|черновик|новое', caseSensitive: false)
              .hasMatch(matches.first.status)) {
        return SubmitResult(
            success: true,
            message: l10n.portalStatus(matches.first.status));
      }
      return SubmitResult(
          success: false,
          message:
              l10n.submissionPending);
    });
