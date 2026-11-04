// Offline-Speicher der Kasse. Beim ersten Öffnen mit Internet werden alle
// Dateien dieser Version gespeichert; danach startet die App auch ohne Netz.
// Eine neue Version lädt sich im Hintergrund und gilt ab dem nächsten Start.
// VERSION und PRECACHE setzt tool/web/finalize_web.py beim Bauen.
const VERSION = '__VERSION__';
const PRECACHE = __PRECACHE__;
const CACHE = 'kasse-' + VERSION;
const RUNTIME = 'kasse-fremd';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      cache.addAll(PRECACHE.map((path) => new Request(path, { cache: 'reload' })))),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key !== CACHE && key !== RUNTIME) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  if (url.origin === self.location.origin) {
    // Eigene Dateien: aus dem Speicher dieser Version, sonst aus dem Netz.
    event.respondWith((async () => {
      const cache = await caches.open(CACHE);
      const key = request.mode === 'navigate' ? 'index.html' : request;
      const hit = await cache.match(key, { ignoreSearch: true });
      if (hit) return hit;
      try {
        const response = await fetch(request);
        // Nachgeladenes (z. B. Browser-Varianten) für den Offline-Betrieb merken.
        if (response.ok && request.mode !== 'navigate') await cache.put(request, response.clone());
        return response;
      } catch (e) {
        return (await cache.match('index.html')) || Response.error();
      }
    })());
    return;
  }

  // Fremde Dateien (z. B. Ersatzschriften für Emojis): einmal laden, dann
  // aus dem Speicher.
  event.respondWith((async () => {
    const cache = await caches.open(RUNTIME);
    const hit = await cache.match(request);
    if (hit) return hit;
    const response = await fetch(request);
    if (response.ok || response.type === 'opaque') await cache.put(request, response.clone());
    return response;
  })());
});
