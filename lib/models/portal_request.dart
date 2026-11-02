import '../services/locale_service.dart';

class RequestOption {
  final String id;
  final String name;

  const RequestOption({required this.id, required this.name});

  factory RequestOption.fromJson(Map<String, dynamic> json) => RequestOption(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );
}

class RequestListItem {
  static String get waitingMessage => l10n.waitingForForm;
  final String id;
  final String title;
  final String category;
  final String status;
  final String updated;
  final String editUrl;

  String get normalizedStatus =>
      status.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  bool get canFill => normalizedStatus == 'получение информации';
  bool get isNew => normalizedStatus == 'новое';
  String get displayStatus => canFill
      ? l10n.uiOpenForm
      : status.isEmpty
          ? l10n.noStatus
          : status;

  const RequestListItem({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.updated,
    required this.editUrl,
  });

  factory RequestListItem.fromJson(Map<String, dynamic> json) =>
      RequestListItem(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        updated: (json['updated'] ?? '').toString(),
        editUrl: (json['edit_url'] ?? '').toString(),
      );
}

class RequestField {
  final String name;
  final String label;
  final String type;
  final bool required;
  final dynamic value;
  final List<RequestOption>? options;
  final String hint;

  const RequestField({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    this.value,
    this.options,
    this.hint = '',
  });

  factory RequestField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List?;
    return RequestField(
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      required: json['required'] == true,
      value: json['value'],
      options: rawOptions
          ?.map((e) => RequestOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RequestForm {
  final String action;
  final String method;
  final List<RequestField> fields;
  final Map<String, String> hidden;
  final String notice;
  final bool editable;
  final bool hasUnsupportedFields;
  final List<RequestAttachment> attachments;
  final String? templateUrl;

  const RequestForm({
    required this.action,
    required this.method,
    required this.fields,
    this.hidden = const {},
    this.notice = '',
    this.editable = true,
    this.hasUnsupportedFields = false,
    this.attachments = const [],
    this.templateUrl,
  });

  factory RequestForm.fromJson(Map<String, dynamic> json) => RequestForm(
        action: (json['action'] ?? '').toString(),
        method: (json['method'] ?? 'POST').toString(),
        fields: (json['fields'] as List? ?? [])
            .map((e) => RequestField.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RequestAttachment {
  final String fieldId;
  final String inputName;
  final String label;
  final String uploadUrl;
  final List<String> extensions;
  final bool required;
  final bool uploaded;

  const RequestAttachment(
      {required this.fieldId,
      required this.inputName,
      required this.label,
      required this.uploadUrl,
      required this.extensions,
      required this.required,
      this.uploaded = false});
}
