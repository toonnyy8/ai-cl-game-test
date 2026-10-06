# RAVEN EDGE — Audio

Zero assets: every sound is synthesized in Lisp at startup (engine toolkit `engine/lisp/audio.lisp`, mixer `engine/c/audio.c`, the game's sounds `game/lisp/sounds.lisp`),
copied into malloc'd C memory, and played by a small C mixer on an SDL3 audio
stream. Demo: `./build.sh audio-demo game/lisp/package.lisp game/lisp/sounds.lisp tests/audio-demo.lisp`,
then `node tools/run.mjs dist/audio-demo --secs 6 --script steps.json`
(keys `1-0 Q W E T Y U I O P A S D F G` = sounds, `M` = music, `R` = rain, `Z` = positional clang).

## Lisp API

| call | effect |
|---|---|
| startup (no call needed) | Games registered with `RUN-GAME` get the device opened and the bank synthesized by the engine's startup steps, one sound per browser frame (`audio-init-begin` / `-sound` / `-end`, engine/lisp/app.lisp), with a GC after each. If audio can't be used the game stays silent (every other call then returns -1 or does nothing). Set `*audio-debug*` to T to log per-sound stats (the stats pass is an unboxed loop: ~10 KB per sound, whatever its length). `(list-sounds)` / `(sound-loop-p key)` list the bank. |
| `(play-sfx key &key (gain 1.0) (pitch 1.0) (pan 0.0) (pitch-jitter 0.05))` → voice id or -1 | Plays one sound once. Pan is -1 (left) to 1 (right). Pitch is a playback-rate ratio, randomly varied by ±`pitch-jitter`. |
| `(play-sfx-at key x y z listener-x listener-z listener-yaw &key gain pitch pitch-jitter)` | Positional version. Gain = `gain/(1+d/8)`. The yaw rotates about +Y: yaw 0 looks down -Z with +X on the right. |
| `(start-loop key &key (gain 1.0))` → id / `(stop-loop id &optional (fade 0.15))` | Looping sounds on the sfx bus (for example `:rain`). `stop-loop` fades out any voice id; `(set-loop-gain id g)` re-gains a running loop. |
| `(music-play &optional (key :music))` / `(music-stop &optional (fade 1.0))` / `(music-playing-p)` | The music loop KEY on the music bus (one track at a time). `music-play` does nothing if music is already playing; stop it first to switch tracks. `(music-intensify &optional (key :music))` restarts KEY at pitch 1.12, volume 0.7 (boss phase 2). |
| `(set-music-volume v)` | Music bus gain from 0 to 2 (default 0.55). The master and sfx bus gains are fixed at 1. |
| `(audio-locked-p)` | T while the browser still holds the AudioContext suspended (the title shows a click hint). |
| `(audio-stats)` → `(values voices frames-mixed peak ctx)` | Debug values. `peak` is the output peak since the last call. `ctx` is 0 none, 1 suspended, 2 running. |

Sound keys: `:slash-light :slash-heavy :hit-flesh :hit-heavy :clang :parry :dodge
:jump :land :footstep :kunai-throw :kunai-hit :enemy-death :obliterate
:raven-burst :player-hurt :brute-slam :warn :boss-roar :ui-move :ui-select
:wave-start :victory :game-over`. The loops are `:rain` (4 s) and `:music` (20 s, via `music-play`).
`:obliterate` starts with a reverse swell, so its impact lands **300 ms** after
the call.

## Mixer design: pure-C stream callback

`SDL_OpenAudioDeviceStream(default playback, {F32, 2 ch, 48000}, au_cb)`. The
callback `au_cb` mixes the requested number of frames in C (32 voices), then
applies master gain and a peak limiter (instant attack to 0.9, ~100 ms release).

The mixer is fed this way, not topped up once per frame from Lisp, for three reasons:
* On the web, SDL 3.2.4 drives the callback from a `ScriptProcessorNode`
  `onaudioprocess` event (2048-frame buffers, about 43 ms). JS runs one thing
  at a time, so the event can only fire between frames, never while Lisp code
  is running. The callback never touches Lisp objects either, which follows the
  GC rule.
* Frame hitches, long GCs and a background tab don't starve the audio, and
  there is no queue to catch up on.
* SDL resamples if the AudioContext rate isn't 48 kHz (44.1 kHz devices).

`play-sfx` and similar calls take `SDL_LockAudioStream`. It costs nothing on
the web and makes native builds thread-safe. Voice ids are `serial<<5 | slot`,
so a stale id never stops a newer voice. When all 32 voices are busy, the new
sound takes over the one-shot with the lowest `gain × amp × remaining fraction`
(the quietest or nearest to finishing). Loops are never taken over.

## Autoplay (browser)

The AudioContext starts `suspended` until the user makes a gesture. SDL 3.2.4
(`src/audio/emscripten/SDL_emscriptenaudio.c`) runs a silence timer while the
context is suspended. That timer keeps calling our callback, so voices keep
moving forward, and it calls `audioContext.resume()` once
`navigator.userActivation.hasBeenActive` is true. To avoid depending on a timer
(Safari wants `resume()` inside the gesture itself), `au_open` also installs
capture listeners for `keydown`, `pointerdown` and `touchend` on `window`. They
resume `Module.SDL3.audioContext` directly inside the gesture handler.

Verified in headless Chrome with `--autoplay-policy=document-user-activation-required`:
the state is `suspended` before the first key and `running` after it.

## Synthesis toolkit (`au-` prefix, all in `engine/lisp/audio.lisp`)

* Buffers are `(simple-array single-float (*))` at 48 kHz, mono.
  `au-render` is the core macro. It adds a per-sample expression into a buffer
  over a time window, with typed state variables (`tt` is the local time).
* Oscillators: `au-sin au-saw au-sqr` take a phase in cycles.
  `au-ph+` advances a phase. `au-rnd` is white noise from a C xorshift, so it
  doesn't cons and runs are deterministic.
* Envelopes and sweeps: `au-ar`, `au-adsr`, `au-env-exp`, `au-sweep`
  (exponential glide).
* Filters: `au-svf!` (TPT state-variable LP/BP/HP with an exponential cutoff
  sweep), `au-onepole!`. Effects: `au-drive!` (tanh), `au-delay!`,
  `au-reverb!` (4 combs + 2 allpasses).
* Utilities: `au-mix!` (a negative offset drops the head), `au-normalize!`,
  `au-fold` (makes a seamless loop by folding the tail onto the head, or
  crossfading it for noise).
* Instruments: `au-noise`, `au-fnoise`, `au-whoosh`, `au-ping!`,
  `au-partials!` (inharmonic metal), `au-thump!` (kicks and impacts),
  `au-taiko!`, `au-gong!`, `au-shaku!` (breathy lead), `au-saws!` (pads and
  drones).
* `(defsound key (:peak p :loop l) body…)` adds a sound to the bank. At init
  each buffer has NaN/Inf zeroed. One-shots also get a 15 Hz DC-block and a
  5 ms end fade. Every buffer is then normalized to `peak`.
* Pink noise for the rain uses the Kellet 3-pole filter inline.

Music: 96 BPM, 8 bars (20 s), D minor pentatonic. It has a taiko, a kick, a
rim and hats, a pumping detuned saw and sine drone on D-Bb-C-A, a filtered saw
arpeggio with delay in bars 5–8, and a shakuhachi lead with delay and reverb.
Everything is rendered 2.5 s past the loop end and folded back, so drum and
reverb tails wrap around without a seam. The loop is mono, 3.8 MB.

## Budget and measurements (headless Chrome, `-O2`)

* Init synthesis for all 26 sounds: **~770–810 ms**, logged at the end of loading when `*audio-debug*` is on.
* Sample memory: 9.1 MB of floats held in C. Each sound's Lisp buffers become garbage
  after its startup step and are collected right after it.
* Sanity log (`*audio-debug*`): every sound has 0 NaN/Inf, a peak equal to its
  target (≤ 0.95), |DC| < 0.0003, and lengths from 80 ms (`ui-move`) to 3.8 s
  (`game-over`).

## SOUL DUEL on Babylon.js (`babylon/src/audio/`)

The Babylon port plays the same bank on WebAudio, still with zero assets: `synth.ts` is this toolkit function by function
(`au-svf!` → `svf`, …), `sounds.ts` the DEFSOUNDs of `duel/lisp/sounds.lisp`, `ichigo-art.lisp` and `senjumaru-art.lisp`
(63 sounds, 16 MB of samples, ~1.3 s to render on a desktop), rendered in a Web Worker after load, menu clicks and the
title loop first. `index.ts` is the mixer: 32 pooled voices (gain + stereo-pan nodes kept; the same steal rule), an sfx
and a music bus (0.55), a master gain, and a soft-clip limiter (linear to 0.8, a tanh knee to 0.95: WebAudio's
compressor halved short transients). `feedback.ts` is FEEDBACK-SYSTEM's sound half (event → sound with the Lisp's gains,
pitches and SFX-AT falloff / pan from the camera); `cues.ts` the PLAY-SFX / SILENCE / CINE-SLASH beats of every DEFCINE
by cine frame (generated from the scripts), so the beats follow sim time whatever the shots do. Music follows the
screen as in flow.lisp (title / select: `:music-title`, a match: `:music`, results: stopped). SETTINGS SOUND (master,
OFF mutes) and MUSIC (`soulduel.sound`, `soulduel.music`). The context is made and resumed inside the first gesture and
suspended while the page is hidden. Checks: `test/audio.test.ts` (every DEFSOUND, every sounding event kind of
feedback.lisp, every emitted / kit sfx key, every cinematic's beats; each sound renders NaN-free at its peak),
`npx tsx tools/audio-stats.ts` (per sound length / peak / RMS / DC), `duelAudio.check()` in the page (an
OfflineAudioContext render through the limiter).
