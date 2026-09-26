// SOUL DUEL page services (docs/DUEL_MOBILE_DESIGN.md G5, G10), loaded from the page head before the game.
// The engine asks through globalThis.gamePage (engine/c/platform.c pf_page_get / pf_page_set):
//   get 0 = touch-first device ((pointer: coarse)), 1 = back gestures since the last ask, 2 = saved HAND (1 right, 2 left)
//   set 0 = battle on / off (the screen wake lock), 1 = save HAND
// On a touch-first device only: the history trap (the back gesture pauses instead of leaving), fullscreen +
// portrait lock on the first tap (Android; iOS has no element fullscreen and runs the installed app standalone),
// and the service worker (sw.js: the app starts offline). A desktop browser gets none of these.
(function () {
  var coarse = !!(window.matchMedia && matchMedia('(pointer: coarse)').matches);
  var back = 0, wakeOn = false, lock = null;
  function stored(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }
  function store(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* private mode: not saved */ } }
  function wake() {
    if (!wakeOn || lock || document.visibilityState !== 'visible' || !navigator.wakeLock) return;
    lock = true;
    navigator.wakeLock.request('screen').then(function (l) {
      lock = l; l.addEventListener('release', function () { lock = null; });
      if (!wakeOn) l.release();
    }).catch(function () { lock = null; });
  }
  document.addEventListener('visibilitychange', wake);   // the lock is dropped when the page hides: take it again
  globalThis.gamePage = {
    get: function (k) {
      if (k === 0) return coarse ? 1 : 0;
      if (k === 1) { var b = back; back = 0; return b; }
      if (k === 2) return +(stored('soulduel.hand') || 0);
      return 0;
    },
    set: function (k, v) {
      if (k === 0 && coarse) { wakeOn = !!v; if (wakeOn) wake(); else if (lock && lock.release) { lock.release(); lock = null; } }
      if (k === 1) store('soulduel.hand', String(v));
    }
  };
  if (!coarse) return;
  var trapped = false, firstTap = true;
  window.addEventListener('popstate', function () { back++; history.pushState({ trap: 1 }, ''); });
  // pointerup: a touch's pointerdown is not a user activation (HTML spec), its pointerup is
  window.addEventListener('pointerup', function () {
    if (!trapped) { trapped = true; history.pushState({ trap: 1 }, ''); }   // after a user activation (Chrome skips it before)
    if (!firstTap) return;
    firstTap = false;
    var ios = /iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.maxTouchPoints > 1 && /Mac/.test(navigator.platform));
    var el = document.documentElement;
    if (!ios && el.requestFullscreen && innerHeight > innerWidth && !matchMedia('(display-mode: fullscreen)').matches)
      el.requestFullscreen({ navigationUI: 'hide' }).then(function () {
        return screen.orientation && screen.orientation.lock ? screen.orientation.lock('portrait') : null;
      }).catch(function () {});
  }, true);
  if ('serviceWorker' in navigator && window.isSecureContext) {
    var had = !!navigator.serviceWorker.controller;          // an update (not the first install): reload onto it once
    navigator.serviceWorker.addEventListener('controllerchange', function () { if (had) location.reload(); had = true; });
    navigator.serviceWorker.register('sw.js').catch(function (e) { console.warn('service worker: ' + e); });
  }
})();
