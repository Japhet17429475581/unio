import 'dart:js_interop';

@JS('unioPromptInstall')
external JSFunction? get _install;
@JS('unioOpenPortal')
external JSFunction? get _portal;

bool promptPwaInstall() =>
    (_install?.callAsFunction() as JSBoolean?)?.toDart ?? false;
void openUniversityPortal() => _portal?.callAsFunction();
