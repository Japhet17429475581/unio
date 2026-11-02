import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'locale_platform.dart';

/// A device preference, independent of account and university data.
/// Russian remains the default for existing installs and unsupported locales.
class LocaleService extends ChangeNotifier {
  static const preferenceKey = 'interface_language_v1';
  Locale _locale = const Locale('ru');
  Locale get locale => _locale;
  AppLocalizations get strings => lookupAppLocalizations(_locale);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final language = preferences.getString(preferenceKey);
    _locale = Locale(language == 'en' ? 'en' : 'ru');
    syncPlatformLanguage(_locale.languageCode);
    notifyListeners();
  }

  Future<void> select(String language) async {
    if (language != 'ru' && language != 'en') {
      throw ArgumentError.value(language, 'language');
    }
    final preferences = await SharedPreferences.getInstance();
    // Persist before applying, so failed writes do not pretend to be saved.
    if (!await preferences.setString(preferenceKey, language)) {
      throw StateError('language_preference_not_saved');
    }
    _locale = Locale(language);
    syncPlatformLanguage(language);
    notifyListeners();
  }
}

final appLocale = LocaleService();

/// Also available in safe error formatters without a BuildContext.
/// App rebuilds are driven by appLocale, not by this getter.
AppLocalizations get l10n => appLocale.strings;
