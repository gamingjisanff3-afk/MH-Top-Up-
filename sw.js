const CACHE_NAME = 'nova-topup-shell-v4';
const APP_SHELL = ['./', './index.html', './manifest.webmanifest', './assets/nova-icon.svg', './assets/bkash-logo.webp', './assets/nagad-logo.webp'];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(APP_SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith('nova-topup-shell-') && key !== CACHE_NAME).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  // Cached page shell: serve instantly when available and refresh the cache in background.
  if (request.mode === 'navigate' && url.origin === self.location.origin) {
    event.respondWith(caches.match('./index.html').then(cached => {
      const fresh = fetch(request).then(response => {
        if (response.ok) caches.open(CACHE_NAME).then(cache => cache.put('./index.html', response.clone()));
        return response;
      }).catch(() => cached);
      return cached || fresh;
    }));
    return;
  }
  // Images (including Supabase public Storage images): cache-first for repeat visits, update in background.
  if (request.destination === 'image') {
    event.respondWith(caches.match(request).then(cached => {
      const fresh = fetch(request).then(response => {
        if (response.ok || response.type === 'opaque') caches.open(CACHE_NAME).then(cache => cache.put(request, response.clone()));
        return response;
      }).catch(() => cached);
      return cached || fresh;
    }));
    return;
  }
  if (url.origin === self.location.origin) {
    event.respondWith(caches.match(request).then(cached => cached || fetch(request).then(response => {
      if (response.ok) caches.open(CACHE_NAME).then(cache => cache.put(request, response.clone()));
      return response;
    })));
  }
});
