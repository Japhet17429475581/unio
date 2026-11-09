# UNIO AI and navigation — beta.15

Android release: `1.0.0-beta.15+16`, 10 November 2026.

The app opens directly to the original timetable. Students and guests have four
bottom tabs: Schedule, Grades, University, and UNIO AI. Grades are no longer a
duplicate University entry. An assistant grade action selects the same Grades
tab; conversations and drafts survive tab changes. Personal grades remain lazy.
Settings and real notification preferences use the timetable header controls.
Teacher capabilities and existing university modules are preserved.

UNIO AI uses the familiar Material three-sparkle icon again, with no custom
star shape. During real requests, a restrained purple gradient changes its tint,
while a bounded background wash and the composer's narrow edge respond to the
current activity. Existing client/server status labels are preserved. There are
no fabricated processing steps or artificial streaming delays.

`UnioAiMotion` shares two animation controllers across the chat. Custom painters,
repaint boundaries, and small icon-only animation builders avoid rebuilding
messages each frame. Entrance motion is finite; looping stops after completion,
cancellation, hiding the AI tab, backgrounding, or enabling reduced motion.

The references were [Google Design's Gemini illustration system](https://design.google/library/gemini-ai-visual-design)
and the owner's [Neural Expressive review](https://www.androidauthority.com/gemini-neural-expressive-android-app-hands-on-3668985/).
UNIO keeps its own purple palette, original icon, working controls, and university
cards. No Gemini logo, model picker, voice/attachment placeholders, or invented
sources were added.

AI endpoints, RAG, consent, bounded request context, local chat storage, account
isolation, and direct Android portal authentication are unchanged. No backend
deployment, schema migration, or new dependency is required.

The current and following timetable weeks still prefetch in parallel; pending
week refreshes reuse the same request. Updating the account/theme with Settings
open notifies that sibling route after the current frame.

Validation includes static analysis, existing Flutter regression tests, motion
pause/resume and reduced-motion tests, large text with keyboard, guest access,
account upgrades, and chat preservation through the Grades action. Screenshots
and browser fixtures use synthetic data; live university accounts and physical
Android devices were not used for this update.

This is an Android-only release. Existing PWA bundles and deployment are not
updated. APKs retain the previous test signing certificate for in-place updates.
