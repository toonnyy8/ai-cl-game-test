// cues.ts <- the PLAY-SFX / SILENCE / CINE-SLASH beats of every DEFCINE (cinema.lisp, yama / ken / rukia / ichigo-art /
// senjumaru .lisp), by cinematic name and frame: [frame, key, pitch?, gain?] plays KEY (not positional); [frame, '', n] is a
// SILENCE beat of n frames (the music down to a tenth, the sfx bus muted). Generated from the Lisp scripts; cinematics are
// sim time, so the beats follow the cine frame (cf) whatever the renderer's shots do.
export type Cue = [number, string, number?, number?];
export const CUES: Record<string, Cue[]> = {
  'soul-break-cine': [[0, 'kikon-slash'], [28, '', 12], [40, 'konpaku-shatter']],
  'intro-cine': [[250, 'fight']],
  'ko-cine': [[0, 'ko']],
  'time-cine': [[0, 'ko']],
  'ic-kikon-cine': [[0, 'whoosh-heavy', 1.1], [12, '', 58], [70, 'awaken-rise', 0.8], [100, 'getsuga', 1.2], [100, 'awaken-boom', 0.7, 0.6], [128, 'getsuga'], [138, 'explode', 0.6], [160, 'getsuga', 0.7], [160, 'konpaku-shatter']],
  'ic-kessa-kikon-cine': [[0, 'clone', 0.8], [12, 'hoho-out'], [12, '', 14], [34, 'cut'], [50, 'cut', 1.1], [66, 'cut', 0.95], [82, 'cut', 1.15], [100, 'cut-heavy'], [100, 'clone', 0.6], [110, '', 10], [124, 'konpaku-shatter'], [124, 'explode', 0.6, 0.6]],
  'ic-kessa-getsuga-cine': [[0, '', 12], [12, 'awaken-rise', 0.5], [100, 'getsuga', 0.6], [100, 'explode', 0.5], [112, '', 20], [140, 'konpaku-shatter'], [140, 'chain-snap']],
  'ic-kessa-cine': [[0, '', 12], [12, 'awaken-rise', 0.6], [58, 'awaken-boom', 1.2], [70, 'chain-rattle'], [70, 'awaken-boom'], [80, 'chain-rattle', 0.8]],
  'ken-kikon-cine': [[12, '', 52], [70, 'cut'], [70, 'laugh'], [98, 'cut'], [122, '', 20], [142, 'cut-heavy'], [142, 'kikon-slash'], [142, 'konpaku-shatter'], [152, 'laugh']],
  'ken-sky-split-cine': [[0, 'whoosh-cleaver'], [12, '', 56], [68, 'cut-heavy'], [68, 'kikon-slash'], [68, 'ground-crack']],
  'ken-nozarashi-cine': [[0, 'awaken-rise'], [26, 'awaken-boom'], [58, '', 20], [78, 'whoosh-cleaver']],
  'ken-bankai-cine': [[0, '', 12], [14, 'yachiru-call'], [58, 'awaken-boom'], [58, 'laugh', 0.7], [78, '', 20]],
  'ken-oni-kikon-cine': [[0, 'whoosh-cleaver'], [12, '', 56], [68, 'cut-heavy'], [68, 'kikon-slash'], [68, 'ground-crack'], [132, 'laugh', 0.8]],
  'ru-kikon-cine': [[0, 'whoosh-heavy', 1.2], [12, '', 58], [70, 'frost-tick'], [100, 'ice-rise'], [128, '', 22], [150, 'ice-shatter'], [150, 'konpaku-shatter']],
  'ru-hakka-cine': [[0, 'freeze'], [12, '', 18], [24, 'awaken-boom', 1.3], [88, 'ice-rise'], [88, 'awaken-rise', 0.6], [118, 'kikon-slash'], [136, '', 20], [156, 'ice-shatter'], [156, 'konpaku-shatter'], [174, 'hand-crack']],
  'ru-awaken-cine': [[0, 'awaken-rise', 1.2], [12, '', 26], [38, 'frost-tick'], [46, 'frost-tick'], [54, 'frost-tick'], [62, 'awaken-boom', 1.2]],
  'sj-kikon-cine': [[0, 'thread-zip'], [12, '', 58], [70, 'thread-zip'], [80, 'thread-zip'], [90, 'thread-zip'], [128, '', 22], [150, 'needle-burst'], [150, 'konpaku-shatter']],
  'sj-hata-cine': [[0, 'cloth-unfurl'], [12, 'cloth-unfurl'], [98, 'awaken-rise', 0.8], [126, 'shears'], [150, 'konpaku-shatter']],
  'sj-tsuji-cine': [[0, '', 12], [20, 'candle-out'], [30, 'candle-out'], [40, 'candle-out'], [46, 'awaken-rise', 0.7], [80, 'cloth-unfurl'], [80, 'awaken-boom']],
  'yama-kikon-cine': [[0, 'fire-roar'], [12, '', 52], [120, '', 22], [142, 'explode'], [142, 'konpaku-shatter']],
  'yama-tenchi-cine': [[12, '', 56], [68, 'kikon-slash'], [86, 'konpaku-shatter'], [86, 'sizzle']],
  'yama-bankai-cine': [[0, 'awaken-rise'], [40, '', 20], [60, 'awaken-boom']],
};
