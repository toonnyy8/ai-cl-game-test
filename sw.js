// SOUL DUEL's service worker: the installed app starts offline (the manual too). build.sh replaces the version below
// with a hash of the build and the page files, so every new build installs a fresh cache; pwa.js reloads the page once when the new worker takes
// over, and the old caches are deleted. Everything is served cache-first from ONE version, so index.html, index.js
// and index.wasm always come from the same build (a network-first index.html could pair a new page with an old
// index.js / index.wasm until the reload).
var VERSION = 'soulduel-141b5a01ef30';
var FILES = ['./', 'index.html', 'index.js', 'index.wasm', 'pwa.js', 'manifest.webmanifest', 'manual.html',
             'icon-192.png', 'icon-512.png', 'icon-maskable-512.png', 'apple-touch-icon.png'];
self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(VERSION)
    .then(function (c) { return c.addAll(FILES.map(function (f) { return new Request(f, { cache: 'reload' }); })); })
    .then(function () { return self.skipWaiting(); }));
});
self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys()
    .then(function (ks) { return Promise.all(ks.filter(function (k) { return k !== VERSION; }).map(function (k) { return caches.delete(k); })); })
    .then(function () { return self.clients.claim(); }));
});
self.addEventListener('fetch', function (e) {
  if (e.request.method !== 'GET' || new URL(e.request.url).origin !== location.origin) return;
  e.respondWith(caches.open(VERSION).then(function (c) {
    return c.match(e.request, { ignoreSearch: true }).then(function (r) { return r || fetch(e.request); });
  }));
});
