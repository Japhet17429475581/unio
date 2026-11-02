import 'package:flutter/services.dart';

/// Read the release source of truth, without a second hardcoded version.
Future<String> loadAppVersion() async {
  final manifest = await rootBundle.loadString('pubspec.yaml');
  final version = RegExp(r'^version:\s*([^\s+]+)', multiLine: true)
      .firstMatch(manifest)
      ?.group(1);
  if (version == null) throw const FormatException('Missing app version');
  return version;
}
