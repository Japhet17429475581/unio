# UNIO

A university companion built with Flutter for Android and the web. UNIO brings
timetables, coursework notes, grades, university news, document requests, and a
university assistant into one interface.

The current university integration targets VGSPU. UNIO is an independent project;
this repository does not imply official university endorsement.

## Downloads

- [Android APKs and release notes](https://github.com/Japhet17429475581/unio/releases)
- [Backend source](https://github.com/Japhet17429475581/backforunio)

Choose the universal APK when unsure about the device architecture. Architecture
specific APKs provide smaller downloads. Install an update over the existing app
to retain local data; uninstalling can remove it.

## Features

The app opens directly to the timetable. Student navigation is **Schedule |
Grades | University | UNIO AI**; the original Settings screen is available from
the timetable header. Grades load only when explicitly opened.

- Student and teacher timetables, group search, and automatic background loading
  of both the current and following weeks into the device cache.
- Guest access, direct Android university authentication, and a separate web
  portal bridge for browser restrictions.
- Grades and assessment breakdowns, document requests, attachments, and Word
  templates supported by the university portal.
- Local lesson notes with photo galleries; there is no fixed photo-count limit,
  while individual file-size and device-storage limits still apply.
- University news, stories, teacher search, and timetable-based room lookup.
- Local Android notifications, an Android home-screen widget, and optional web
  push where configured and supported.
- Russian and English interfaces, light and dark themes, privacy controls,
  account deletion, and separate analytics consent.
- UNIO AI with native schedule, grade, and news cards; document-based answers;
  official sources; and local, searchable, separate conversations.

The assistant handles personal grade cards locally. Document questions use the
backend's retrieval pipeline and an external language provider after consent.
The complete local chat archive is not uploaded to the UNIO backend. Browser
storage can be cleared or evicted and does not offer the same protection as
Android's platform-backed secure storage. AI answers can be wrong.

## Stack and layout

Flutter / Dart, Material UI, HTTP and Dio, platform secure storage,
SharedPreferences, file storage / IndexedDB, and Android Kotlin integrations.
The backend uses FastAPI, PostgreSQL, Redis, and PostgreSQL full-text retrieval.

```text
lib/
  config/       Theme, university, and API configuration
  l10n/         Russian and English translations
  models/       Domain and versioned chat payloads
  screens/      Application screens
  services/     Networking, persistence, consent, and platform integrations
  widgets/      Shared UI components
android/        Native integrations, widget, and backup rules
web/            PWA shell and service worker
test/           Unit and widget tests with synthetic data
tools/          Web packaging and browser smoke tests
deploy/pwa/     Example PWA container and reverse proxy
docs/           Implementation notes and known limitations
```

Backend code is maintained in its own repository. Older implementation notes may
refer to the former combined-workspace location `lib/backend`.

## Development

The release was built with Flutter **3.47.5**, Dart **3.13.4**, Java **17**, and
Android SDK tooling. Install Flutter and the Android SDK, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_HOST=your-api.example
```

`API_HOST` is a hostname, without `https://` or a path. Requests use HTTPS. The
current testing host remains the default in `lib/config/api_config.dart`.
Do not put database credentials or the AI-provider API key into Flutter defines.

Generated localization files are checked in. After editing the ARB files:

```sh
flutter gen-l10n
```

## Android builds

Android checks `app-update.json` in this repository on startup / resume, at most
once every six hours. Settings also offers a manual check. Publish an APK first,
then update the manifest's `versionCode`, version, APK link, and RU/EN notes.
This also supports beta releases; no GitHub token is embedded in the app.

```sh
flutter build apk --release
flutter build apk --release --split-per-abi
```

Build output is under `build/app/outputs/flutter-apk/`. Version and Android
version code come from `pubspec.yaml`; increment them before distributing an
update. APKs are published as GitHub Release assets, not committed into source.
Direct-download ABI variants share the same version code, allowing users to
switch between universal and smaller APK updates without an uninstall.

The current closed-test signing configuration uses the local Android debug key
to preserve compatibility with existing testers. A clean machine generates a
different key, so its APK cannot update an existing installation signed elsewhere.
Configure protected release signing before public store distribution. Never
commit signing keys, `key.properties`, or passwords.

MyTracker is Android-only and starts after separate consent. Use
`--dart-define=MYTRACKER_ENABLED=false` to disable its runtime initialization for a
build. Debug analytics remain disabled unless explicitly enabled.

## PWA builds

```sh
flutter build web --release --pwa-strategy=none --no-web-resources-cdn
python tools/package_pwa.py
```

Deploy the generated `build/UNIO-PWA-<version>.zip` as a complete package. Static
files are inside `public/`; the archive also includes an example container and
Nginx configuration. Keep the origin stable to preserve browser-local data.
HTTPS is required outside localhost.

For portal functions, configure the backend's web-portal origins and encryption
keys, and route `/api/` to that backend using the deployment example. A static
host alone cannot perform university portal operations. Web permissions are
subject to browser / OS support; the Android widget is not available in a PWA.

## Validation and privacy

Tests mock the university and use synthetic accounts. They do not send real
applications, inspect production databases, or prove behavior on every device.
Run physical-device and production-HTTPS smoke checks before wider rollout.
The optional `tools/test_pwa_browser.py` smoke test needs Python, Playwright,
Google Chrome, and a packaged `build/web` directory; it mocks all backend calls.

Chat history uses versioned payloads and account-specific storage namespaces.
Ordinary logout closes access to the current session; explicit data deletion
also clears local records. See [local chat history](docs/assistant_local_history.md)
and [privacy implementation](docs/privacy_implementation.md).

This software and its tests are not a certification of legal compliance.
