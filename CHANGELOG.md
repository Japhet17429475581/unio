# Changelog

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
