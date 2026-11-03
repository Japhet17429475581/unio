UNIO PWA beta.13: updated Bothost API host, local AI history and two-week timetable cache.
Assistant backend setup: docs/assistant.md in the project. Never put the DeepSeek key here.
Interface language: Settings / Preferences / Language (Russian or English).
The language is saved in this browser. University content and legal documents
remain in their original language.

Full portal functionality REQUIRES the updated backend, migrations 002/003,
backend environment secrets and a same-origin HTTPS proxy for /api/.
Uploading public/ alone to a static-only host does not provide portal login.

1. Deploy the updated backend with requirements.txt and all migrations/.
2. Run tools/prepare_pwa_backend.py --origin https://YOUR-PWA-DOMAIN and import
   generated values into BACKEND environment secrets. Never publish the file.
3. Upload this entire archive as a separate Docker application. Expose port
   8080 behind HTTPS. UNIO_API_UPSTREAM is the HTTPS backend origin without a
   trailing slash. Default: current Bothost backend.
4. Keep the domain and keys stable. Set this exact origin in WEB_PORTAL_ORIGINS.
   Forward Set-Cookie unchanged; disable caches and sensitive logging for /api/.
5. Test login/restart, grades, requests, attachments, Web Push and logout on
   real devices before distributing the URL.

Do not upload .env, keys, database dumps, credentials or the Flutter SDK.
Do not put backend files or generated private configuration inside public/.
This archive updates the website only; backend deployment is separate.

Android keeps direct university login. PWA login handles credentials briefly
on the backend, retaining encrypted cookies and token hashes. No MyTracker in
PWA. Native Android widgets cannot run in PWA. iPhone Web Push needs an installed
Home Screen PWA and iOS 16.4+. University expiry may require a new login.
Browser storage is not native secure storage.

Local static preview: python -m http.server 8080 --directory public
This does not proxy the portal API. Full testing needs HTTPS and the backend
proxy. See docs/pwa.md in the repository for setup and verification details.
