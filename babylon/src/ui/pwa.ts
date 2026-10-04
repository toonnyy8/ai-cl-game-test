// pwa.ts <- the service-worker part of duel/web/pwa.js: on a touch-first device in a secure context, register sw.js (the
// installed app starts offline; vite.config.ts writes sw.js with this build's file list and version) and reload once
// when an update's worker takes over. The back trap, fullscreen + portrait lock and wake lock are onehand.ts'.
import { COARSE } from '../input/onehand';

if (COARSE && 'serviceWorker' in navigator && isSecureContext && import.meta.env.PROD) {
  let had = !!navigator.serviceWorker.controller;          // an update (not the first install): reload onto it once
  navigator.serviceWorker.addEventListener('controllerchange', () => { if (had) location.reload(); had = true; });
  navigator.serviceWorker.register('sw.js').catch((e) => console.warn('service worker: ' + e));
}
