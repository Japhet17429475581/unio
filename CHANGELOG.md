# Changelog

## 1.0.0-beta.14 — 2026-11-08

- Set the effective date to 11.08.2026 in all four legal documents and
  synchronize consent hashes and versions with the backend and Android.
- Remove the redundant schedule/date banner from teacher timetables.
- Remove the additional "Then…" lesson row from the Android home-screen widget.
- Open assessment details, documents, update checks, and language controls
  without a pressed overlay; retain disclosure-arrow animations.

## 1.0.0-beta.13 — 2026-11-03

- Point Android and the PWA reverse proxy to the replacement Bothost API host.
- Backend domain routing must be enabled on the host before API access works.

## 1.0.0-beta.12 — 2026-11-03

- Check Android updates in the background at most once every six hours.
- Add a manual update check in Settings, with Russian and English messages.
- Offer the official GitHub APK without blocking app access or installing silently.
- Validate public release metadata and allow APK links only from this repository.

For each future release, update `app-update.json` after publishing the APK: raise
`versionCode`, set the version and exact APK URL, and supply short RU/EN notes.
Keep the APK signing key unchanged. Existing beta.11 installations need one
manual update to beta.12 before automatic update checks become available.

## 1.0.0-beta.11 — 2026-11-02

- Automatically fetch and save the current and following timetable weeks in
  parallel, including teacher schedules. Reuse loaded weeks when switching.
- Show local-history storage failures immediately when loading older AI messages.
- Fix news cache page sizes so a small request cannot truncate a later large one.
- Clean up PostgreSQL and Redis after failed initialization, and stop background
  workers even when another shutdown operation fails.
- Make backend test paths independent of the working directory and add a legal
  asset contract fixture for the standalone backend repository.
- Replace an unresolved lint configuration with self-contained correctness rules.
- Keep direct-download APK variants on the same Android version code so switching
  between universal and architecture-specific updates does not require uninstalling.
- Add English setup documentation, environment examples, and CI checks for the
  separate frontend and backend repositories.

The assistant's searchable local chat history, native university cards, official
sources, drafts, and message actions introduced in beta.10 are retained.
