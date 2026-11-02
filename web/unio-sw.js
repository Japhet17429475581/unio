// Filled by tools/package_pwa.py after a successful Flutter release build.
// No user/API/portal responses are ever included in this cache.
const BUILD_ID = '__UNIO_BUILD_ID__';
const FILES = /* UNIO_FILES */ [];
const CACHE = 'unio-shell-' + BUILD_ID;
const BASE = new URL('./', self.location.href);
const URLS = FILES.map(path => new URL(path, BASE).href);
const ALLOWED = new Set(URLS);
const INDEX = new URL('index.html', BASE).href;

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    try {
      for (let i = 0; i < URLS.length; i += 6) {
        await Promise.all(URLS.slice(i, i + 6).map(async url => {
          const response = await fetch(new Request(url, {cache: 'reload', credentials: 'omit'}));
          if (!response.ok || response.redirected) throw new Error('shell_fetch_failed');
          await cache.put(url, response);
        }));
      }
    } catch (error) { await caches.delete(CACHE); throw error; }
  })());
});
self.addEventListener('message', event => {
  if (event.data?.type === 'ACTIVATE_UPDATE') self.skipWaiting();
});
self.addEventListener('push', event => {
  event.waitUntil((async () => {
    let data;
    try { data = event.data.json(); } catch (_) { return; }
    const screen = data.screen === 'requests' ? 'requests' : 'schedule';
    await self.registration.showNotification('UNIO', {
      body: screen === 'requests' ? 'Обновился статус заявления. Проверь его в UNIO.' : 'Скоро начнётся пара. Открой расписание.',
      icon: new URL('icons/Icon-192.png', BASE).href,
      badge: new URL('icons/Icon-192.png', BASE).href,
      data: {screen},
    });
  })());
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil((async () => {
    const screen = event.notification.data?.screen === 'requests' ? 'requests' : 'schedule';
    const windows = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    const target = windows.find(client => new URL(client.url).origin === BASE.origin && client.url.startsWith(BASE.href));
    if (target) { await target.focus(); target.postMessage({type: 'UNIO_OPEN', screen}); }
    else { const url = new URL(BASE); url.searchParams.set('screen', screen); await self.clients.openWindow(url.href); }
  })());
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = (await caches.keys()).filter(key => key.startsWith('unio-shell-'));
    const old = keys.filter(key => key !== CACHE);
    await Promise.all(old.slice(0, -1).map(key => caches.delete(key)));
  })());
});
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== BASE.origin ||
      request.headers.has('Authorization') || request.headers.has('X-Unio-Token')) return;
  const entry = request.mode === 'navigate' &&
      (url.pathname === BASE.pathname || url.pathname === new URL(INDEX).pathname);
  if (!entry && !ALLOWED.has(url.href)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(entry ? INDEX : url.href);
    return cached || fetch(request);
  })());
});
