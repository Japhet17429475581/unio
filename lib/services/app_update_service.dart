import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _manifestUrl =
    'https://raw.githubusercontent.com/Japhet17429475581/unio/main/app-update.json';
const _lastCheckKey = 'app_update_checked_at_v1';
bool _checking = false;

bool get supportsAppUpdates =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Public release metadata only: no account credentials or user information.
Future<void> checkForAppUpdate(BuildContext context,
    {bool manual = false}) async {
  if (!supportsAppUpdates || _checking) return;
  // Development sessions must not poll releases or suggest a signed APK update.
  // Manual checks remain available while debugging.
  if (!manual && !kReleaseMode) return;
  _checking = true;
  final english = Localizations.localeOf(context).languageCode == 'en';
  String text(String ru, String en) => english ? en : ru;
  void message(String ru, String en) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text(ru, en))));
    }
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final previous = prefs.getInt(_lastCheckKey);
    if (!manual &&
        previous != null &&
        now >= previous &&
        now - previous < const Duration(hours: 6).inMilliseconds) return;
    // Throttle failed checks too; manual checks always bypass this timestamp.
    await prefs.setInt(_lastCheckKey, now);
    final client = http.Client();
    late http.Response response;
    try {
      response = await client
          .get(Uri.parse(_manifestUrl))
          .timeout(const Duration(seconds: 8));
    } finally {
      client.close();
    }
    if (response.statusCode != 200 || response.bodyBytes.length > 32768) {
      throw const FormatException('Invalid release metadata');
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final code = data['versionCode'];
    final version = data['version'];
    final download = Uri.tryParse('${data['apkUrl'] ?? ''}');
    if (data['schemaVersion'] != 1 ||
        code is! int ||
        code <= 0 ||
        version is! String ||
        !RegExp(r'^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$').hasMatch(version) ||
        download == null ||
        download.scheme != 'https' ||
        download.host != 'github.com' ||
        download.userInfo.isNotEmpty ||
        download.hasQuery ||
        download.hasFragment ||
        download.port != 443 ||
        !download.path
            .startsWith('/Japhet17429475581/unio/releases/download/') ||
        !download.path.endsWith('.apk')) {
      throw const FormatException('Invalid release metadata');
    }
    final source = await rootBundle.loadString('pubspec.yaml');
    final installed = int.parse(
        RegExp(r'^version:\s*\S+\+(\d+)\s*$', multiLine: true)
            .firstMatch(source)!
            .group(1)!);
    if (!context.mounted) return;
    if (code <= installed) {
      if (manual) message('Установлена последняя версия', 'You are up to date');
      return;
    }
    // Do not interrupt another screen or an existing modal with an auto-check.
    if (!manual && ModalRoute.of(context)?.isCurrent != true) return;
    final notes = data[english ? 'notesEn' : 'notesRu'];
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(text('Доступно обновление', 'Update available')),
              content: SingleChildScrollView(
                  child: Text([
                'UNIO $version',
                if (notes is String && notes.trim().isNotEmpty)
                  notes.substring(0, notes.length.clamp(0, 2000)),
              ].join('\n\n'))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(text('Позже', 'Later'))),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(text('Обновить', 'Update'))),
              ],
            ));
    if (accepted == true) {
      final opened =
          await launchUrl(download, mode: LaunchMode.externalApplication);
      if (!opened)
        message('Не удалось открыть загрузку', 'Could not open the download');
    }
  } catch (_) {
    if (manual)
      message('Не удалось проверить обновления. Попробуйте позже.',
          'Could not check for updates. Try again later.');
  } finally {
    _checking = false;
  }
}
