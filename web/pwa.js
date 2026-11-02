(() => {
  'use strict';
  // The Flutter preference is mirrored only to paint the pre-Flutter shell.
  // Contains a language code, never account or portal data.
  let language = 'ru';
  let bootFailed = false;
  const shellText = {
    ru: {
      title: 'UNIO · Веб-бета', boot: 'Твой университет рядом',
      failure: 'Не удалось загрузить UNIO. Проверьте соединение и попробуйте снова.',
      retry: 'Попробовать снова',
      update: 'Доступна новая версия UNIO. Сохраните заметку перед обновлением.',
      now: 'Обновить', later: 'Позже',
    },
    en: {
      title: 'UNIO · Web beta', boot: 'Your university nearby',
      failure: 'Could not load UNIO. Check your connection and try again.',
      retry: 'Try again',
      update: 'A new version of UNIO is available. Save your note before updating.',
      now: 'Update', later: 'Later',
    },
  };
  const paintLanguage = () => {
    const text = shellText[language];
    document.documentElement.lang = language;
    document.title = text.title;
    for (const [selector, value] of [
      ['#boot-message', bootFailed ? text.failure : text.boot],
      ['#retry', text.retry], ['#update > span', text.update],
      ['#update-now', text.now], ['#update-later', text.later],
    ]) {
      const element = document.querySelector(selector);
      if (element) element.textContent = value;
    }
  };
  window.unioSetLanguage = value => {
    language = value === 'en' ? 'en' : 'ru';
    try { localStorage.setItem('unio_interface_language', language); } catch (_) {}
    paintLanguage();
  };
  try { language = localStorage.getItem('unio_interface_language') === 'en' ? 'en' : 'ru'; } catch (_) {}
  paintLanguage();
  let pushListener = null;
  window.unioPushSupported = () => 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  window.unioPushSubscribe = async key => {
    if (!window.unioPushSupported()) throw new Error('push_unavailable');
    // Permission must be requested directly in the user's button/switch gesture.
    const permission = await Notification.requestPermission();
    if (permission !== 'granted') throw new Error('push_permission_denied');
    const registration = await navigator.serviceWorker.ready;
    const padding = '='.repeat((4 - key.length % 4) % 4);
    const raw = atob((key + padding).replace(/-/g, '+').replace(/_/g, '/'));
    const publicKey = Uint8Array.from(raw, char => char.charCodeAt(0));
    const subscription = await registration.pushManager.getSubscription() ||
      await registration.pushManager.subscribe({userVisibleOnly: true, applicationServerKey: publicKey});
    return JSON.stringify(subscription.toJSON());
  };
  window.unioPushCurrent = async () => {
    if (!window.unioPushSupported()) return '';
    const registration = await navigator.serviceWorker.getRegistration();
    if (!registration) return '';
    const subscription = await registration.pushManager.getSubscription();
    return subscription ? JSON.stringify(subscription.toJSON()) : '';
  };
  window.unioPushUnsubscribe = async () => {
    if (!window.unioPushSupported()) return;
    const registration = await navigator.serviceWorker.getRegistration();
    if (!registration) return;
    const subscription = await registration.pushManager.getSubscription();
    if (subscription) await subscription.unsubscribe();
  };
  window.unioPushListen = callback => { pushListener = callback; };
  navigator.serviceWorker?.addEventListener('message', event => {
    if (event.data?.type === 'UNIO_OPEN' && ['schedule', 'requests'].includes(event.data.screen)) {
      pushListener?.(event.data.screen);
    }
  });
  let installEvent = null;
  let registration = null;
  let approvedUpdate = false;
  let reloading = false;
  window.unioBootFailed = () => {
    bootFailed = true;
    paintLanguage();
    document.getElementById('retry')?.removeAttribute('hidden');
  };
  document.getElementById('retry').onclick = () => location.reload();
  setTimeout(() => { if (document.getElementById('boot')) window.unioBootFailed(); }, 45000);
  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault(); installEvent = event;
  });
  window.addEventListener('appinstalled', () => { installEvent = null; });
  window.unioPromptInstall = () => {
    if (!installEvent) return false;
    const event = installEvent; installEvent = null;
    event.prompt().catch(() => {});
    return true;
  };
  window.unioOpenPortal = () => window.open('https://portal.vspu.ru/', '_blank', 'noopener,noreferrer');
  const offerUpdate = () => {
    if (registration?.waiting && navigator.serviceWorker.controller) {
      document.getElementById('update').hidden = false;
    }
  };
  document.getElementById('update-later').onclick = () => {
    document.getElementById('update').hidden = true;
  };
  document.getElementById('update-now').onclick = () => {
    if (registration?.waiting) {
      approvedUpdate = true;
      registration.waiting.postMessage({type: 'ACTIVATE_UPDATE'});
    } else location.reload();
  };
  if ('serviceWorker' in navigator && window.isSecureContext) {
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (approvedUpdate && !reloading) { reloading = true; location.reload(); }
    });
    window.addEventListener('load', async () => {
      try {
        registration = await navigator.serviceWorker.register('unio-sw.js', {updateViaCache: 'none'});
        offerUpdate();
        registration.addEventListener('updatefound', () => {
          registration.installing?.addEventListener('statechange', offerUpdate);
        });
      } catch (_) { /* Online UNIO remains usable if caching is unavailable. */ }
    });
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') registration?.update().catch(() => {});
    });
  }
})();
