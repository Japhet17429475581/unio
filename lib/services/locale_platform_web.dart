import 'dart:js_interop';

@JS('unioSetLanguage')
external JSFunction? get _setLanguage;

void syncPlatformLanguage(String language) =>
    _setLanguage?.callAsFunction(null, language.toJS);
