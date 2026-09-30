// SOUL DUEL page services (docs/DUEL_MOBILE_DESIGN.md G5, G10), loaded from the page head before the game.
// The engine asks through globalThis.gamePage (engine/c/platform.c pf_page_get / pf_page_set):
//   get 0 = touch-first device ((pointer: coarse)), 1 = back gestures since the last ask,
//       3 / 4 = the safe-area inset at the top / bottom, CSS px (env(safe-area-inset-*); tests set gamePage.testInsets = [top, bottom])
//       10 + i = SETTINGS row i as saved (option index + 1; 0 = never saved, or no storage: the game's default)
//       30 + k = ENDLESS best record slot k (roster index i: 30 + 2i stages, 31 + 2i seconds; 0 = none / no storage)
//       100 + 1000 i = the learning CPU's saved table of roster index i: its entry count; 100 + 1000 i + 1 + j = entry j
//       (docs/DUEL_LEARNING.md; localStorage soulduel.learn.<i>, the integers comma-separated)
//   set 0 = battle on / off (the screen wake lock), 1 = open the manual (manual.html, this window), 10 + i = save SETTINGS row i, 30 + k = save ENDLESS slot k,
//       100 + 1000 i + 1 + j = table entry j (kept here), then 100 + 1000 i = n commits the first n entries (0: forget it)
// SETTINGS rows (duel/lisp/control.lisp *SETTINGS*, same order) live in localStorage as soulduel.<name>; every access is
// wrapped in try/catch (private mode / blocked storage: nothing saved, the defaults).
// On a touch-first device only: the history trap (the back gesture pauses instead of leaving), fullscreen +
// portrait lock on the first tap (Android; iOS has no element fullscreen and runs the installed app standalone),
// and the service worker (sw.js: the app starts offline). A desktop browser gets none of these.
(function () {
  var coarse = !!(window.matchMedia && matchMedia('(pointer: coarse)').matches);
  var back = 0, wakeOn = false, lock = null;
  var settings = ['onehand', 'hand', 'split', 'flick', 'camera', 'learn', 'hint'];   // soulduel.hand predates SETTINGS (same values)
  function stored(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }
  function store(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* private mode: not saved */ } }
  var learn = {};                                        // roster index -> the learning CPU's table (integers)
  function ltab(i) {
    if (!learn[i]) { var s = stored('soulduel.learn.' + i); learn[i] = s ? s.split(',').map(Number) : []; }
    return learn[i];
  }
  function wake() {
    if (!wakeOn || lock || document.visibilityState !== 'visible' || !navigator.wakeLock) return;
    lock = true;
    navigator.wakeLock.request('screen').then(function (l) {
      lock = l; l.addEventListener('release', function () { lock = null; });
      if (!wakeOn) l.release();
    }).catch(function () { lock = null; });
  }
  document.addEventListener('visibilitychange', wake);   // the lock is dropped when the page hides: take it again
  var insets = null;                                     // measured once per window size (the game asks every frame)
  window.addEventListener('resize', function () { insets = null; });
  function inset(i) {
    var t = globalThis.gamePage.testInsets;
    if (t) return t[i] | 0;
    if (!insets && document.body) {
      var d = document.createElement('div');
      d.style.cssText = 'position:fixed;visibility:hidden;padding-top:env(safe-area-inset-top);padding-bottom:env(safe-area-inset-bottom)';
      document.body.appendChild(d);
      var cs = getComputedStyle(d);
      insets = [parseFloat(cs.paddingTop) || 0, parseFloat(cs.paddingBottom) || 0];
      d.remove();
    }
    return insets ? Math.round(insets[i]) : 0;
  }
  globalThis.gamePage = {
    get: function (k) {
      if (k === 0) return coarse ? 1 : 0;
      if (k === 1) { var b = back; back = 0; return b; }
      if (k >= 10 && k < 10 + settings.length) return +(stored('soulduel.' + settings[k - 10]) || 0) | 0;
      if (k === 3 || k === 4) return inset(k - 3);
      if (k >= 30 && k < 50) return +(stored('soulduel.endless.' + (k - 30)) || 0) | 0;
      if (k >= 100 && k < 10100) { var t = ltab(((k - 100) / 1000) | 0), j = (k - 100) % 1000; return j ? (t[j - 1] | 0) : t.length; }
      return 0;
    },
    set: function (k, v) {
      if (k === 1) location.href = 'manual.html';        // MODE's MANUAL row; the manual links back to ./
      if (k === 0 && coarse) { wakeOn = !!v; if (wakeOn) wake(); else if (lock && lock.release) { lock.release(); lock = null; } }
      if (k >= 10 && k < 10 + settings.length) store('soulduel.' + settings[k - 10], String(v));
      if (k >= 30 && k < 50) store('soulduel.endless.' + (k - 30), String(v));
      if (k >= 100 && k < 10100) {
        var i = ((k - 100) / 1000) | 0, j = (k - 100) % 1000, t = ltab(i);
        if (j) t[j - 1] = v | 0;
        else { t.length = Math.max(0, v | 0); store('soulduel.learn.' + i, t.join(',')); }
      }
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
