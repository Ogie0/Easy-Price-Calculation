// Offline-Speicher der Kasse. Beim ersten Öffnen mit Internet werden alle
// Dateien dieser Version gespeichert; danach startet die App auch ohne Netz.
// Eine neue Version lädt sich im Hintergrund und gilt ab dem nächsten Start.
// VERSION und PRECACHE setzt tool/web/finalize_web.py beim Bauen.
const VERSION = '11';
const PRECACHE = [
  "assets/AssetManifest.bin",
  "assets/AssetManifest.bin.json",
  "assets/FontManifest.json",
  "assets/NOTICES",
  "assets/assets/articles/bier.png",
  "assets/assets/articles/bratwurst.png",
  "assets/assets/articles/currywurst.png",
  "assets/assets/articles/freier_betrag.png",
  "assets/assets/articles/krakauer.png",
  "assets/assets/articles/longdrink.png",
  "assets/assets/articles/nuggets.png",
  "assets/assets/articles/pfandrueckgabe.png",
  "assets/assets/articles/pommes.png",
  "assets/assets/articles/sekt.png",
  "assets/assets/articles/shot.png",
  "assets/assets/articles/softdrink.png",
  "assets/assets/articles/steak.png",
  "assets/assets/articles/wasser.png",
  "assets/assets/fonts/Roboto-Bold.ttf",
  "assets/assets/fonts/Roboto-Medium.ttf",
  "assets/assets/fonts/Roboto-Regular.ttf",
  "assets/assets/fonts/Roboto_LICENSE.txt",
  "assets/assets/licenses/zxing-js_LICENSE.txt",
  "assets/assets/logo/jgc_logo.png",
  "assets/fonts/MaterialIcons-Regular.otf",
  "assets/shaders/ink_sparkle.frag",
  "assets/shaders/stretch_effect.frag",
  "canvaskit/canvaskit.js",
  "canvaskit/canvaskit.wasm",
  "favicon.png",
  "flutter.js",
  "flutter_bootstrap.js",
  "icons/Icon-192.png",
  "icons/Icon-512.png",
  "icons/Icon-maskable-192.png",
  "icons/Icon-maskable-512.png",
  "icons/apple-touch-icon.png",
  "icons/splash-logo.png",
  "index.html",
  "main.dart.js",
  "manifest.json",
  "version.json",
  "zxing/index.min.js"
];
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
