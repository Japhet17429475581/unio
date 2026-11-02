import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/portal_request.dart';

enum RequestTemplate {
  income('income.docx', 'Заявление о доходах.docx'),
  gss('gss.docx', 'Заявление ГСС.docx');

  final String assetName, fileName;
  const RequestTemplate(this.assetName, this.fileName);
}

/// Match portal field signatures, never a user's changing request number.
RequestTemplate? templateForForm(RequestForm form) {
  final fields = form.fields.map((field) => field.name).toSet();
  if (fields.containsAll({'field_143', 'field_144', 'field_145'})) {
    return RequestTemplate.income;
  }
  final attachments = form.attachments.map((file) => file.fieldId).toSet();
  if (fields.contains('field_36') && attachments.containsAll({'1', '37'})) {
    return RequestTemplate.gss;
  }
  return null;
}

const _exportChannel = MethodChannel('unio/document_export');
const _docxMime =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

/// Returns false when the system save dialog was cancelled.
Future<bool> saveRequestTemplate(RequestTemplate template) async {
  final asset = await rootBundle.load('assets/templates/${template.assetName}');
  final bytes =
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes);
  final file =
      XFile.fromData(bytes, name: template.fileName, mimeType: _docxMime);
  if (kIsWeb) {
    await file.saveTo(template.fileName);
    return true;
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return await _exportChannel.invokeMethod<bool>('saveDocument', {
          'name': template.fileName,
          'bytes': bytes,
          'mimeType': _docxMime,
        }) ??
        false;
  }
  final location = await getSaveLocation(
    suggestedName: template.fileName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Документ Word', extensions: [
        'docx'
      ], uniformTypeIdentifiers: [
        'org.openxmlformats.wordprocessingml.document'
      ]),
    ],
  );
  if (location == null) return false;
  await file.saveTo(location.path);
  return true;
}
