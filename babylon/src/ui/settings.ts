// settings.ts <- duel/lisp/control.lisp *SETTINGS* / ONE-HAND-ON-P + onehand.lisp's SET-SETTING and the page storage of
// duel/web/pwa.js: localStorage "soulduel.<name>" = option index + 1 (0 / missing / blocked storage: the default). The
// same keys as the Lisp build, so both builds on one origin share the choices.

export interface SettingRow { key: string; label: string; opts: string[]; def: number; values?: number[]; note: string; store: string }
export const SETTINGS: SettingRow[] = [
  { key: 'one-hand', label: 'ONE-HAND', opts: ['AUTO', 'ON', 'OFF'], def: 0, note: 'AUTO: ON FOR A TOUCH PHONE HELD UPRIGHT', store: 'onehand' },
  { key: 'hand', label: 'HAND', opts: ['RIGHT', 'LEFT'], def: 0, note: "THE THUMB DECK'S SIDE", store: 'hand' },
  { key: 'tap-split', label: 'TAP SPLIT', opts: ['40%', '45%', '50%', '55%', '60%'], def: 2, values: [0.4, 0.45, 0.5, 0.55, 0.6],
    note: "THE PAD'S TOP PART THAT TAPS K", store: 'split' },
  { key: 'flick', label: 'SENSITIVITY', opts: ['1', '2', '3', '4', '5'], def: 2, values: [40, 34, 28, 23, 18],
    note: 'HIGHER: A SHORTER FLICK', store: 'flick' },
  { key: 'camera', label: 'CAMERA', opts: ['BEHIND', 'SIDE'], def: 0, note: 'VS CPU AND PRACTICE, TWO HANDS', store: 'camera' },
  // ponytail: the rows below are kept (saved, shown) but not in force until learn.lisp / assist.lisp are ported (M6)
  { key: 'learn', label: 'LEARNING CPU', opts: ['ON', 'OFF'], def: 0, note: 'NOT IN THIS BUILD YET (THE CPU LEARNS YOUR HABITS)', store: 'learn' },
  { key: 'hint', label: 'PERFECT HINT', opts: ['OFF', 'ON'], def: 0, note: 'HOHO! OVER YOU WHEN A HOHO NOW IS PERFECT', store: 'hint' },
  { key: 'auto-guard', label: 'AUTO GUARD', opts: ['OFF', 'HOLD U', 'ALWAYS'], def: 0, note: 'ASSIST: NOT IN THIS BUILD YET', store: 'autoguard' },
  { key: 'auto-combo', label: 'AUTO COMBO', opts: ['OFF', 'ON'], def: 0, note: 'ASSIST: NOT IN THIS BUILD YET', store: 'autocombo' },
  { key: 'auto-break', label: 'AUTO BREAK', opts: ['OFF', 'ON'], def: 0, note: 'ASSIST: NOT IN THIS BUILD YET', store: 'autobreak' },
];

export function stored(k: string): string | null { try { return localStorage.getItem(k); } catch { return null; } }
export function store(k: string, v: string): void { try { localStorage.setItem(k, v); } catch { /* private mode: not saved */ } }

const row = (key: string): SettingRow => { const r = SETTINGS.find((s) => s.key === key); if (!r) throw new Error(`no setting ${key}`); return r; };
/** The option index a page value V stands for: V - 1 when it names an option, else the default. */
export const settingFromPage = (r: SettingRow, v: number): number => (v > 0 && v <= r.opts.length ? v - 1 : r.def);
const ix = new Map(SETTINGS.map((r) => [r.key, settingFromPage(r, +(stored('soulduel.' + r.store) ?? 0) | 0)]));

/** KEY's chosen option index. */
export const setting = (key: string): number => ix.get(key) ?? row(key).def;
/** What KEY's chosen option means (its values entry, else its label). */
export const settingValue = (key: string): number | string => { const r = row(key); return (r.values ?? r.opts)[setting(key)]; };
export const settingLabel = (key: string): string => row(key).opts[setting(key)];

const listeners: (() => void)[] = [];
/** Run FN now and after every change (the settings put in force: hand, recogniser knobs, camera). */
export function onSettings(fn: () => void): void { listeners.push(fn); fn(); }
/** Row KEY to option I: in force now and saved. */
export function setSetting(key: string, i: number): void {
  const r = row(key);
  ix.set(key, ((i % r.opts.length) + r.opts.length) % r.opts.length);
  store('soulduel.' + r.store, String(setting(key) + 1));
  for (const f of listeners) f();
}

/** Is a VS CPU / PRACTICE match one-handed for ONE-HAND choice CHOICE (0 AUTO 1 ON 2 OFF), a touch-first device (COARSE)
 *  and a PORTRAIT window? Only where one-hand is offered (coarse or portrait); AUTO: coarse and portrait. */
export const oneHandOnP = (choice: number, coarse: boolean, portrait: boolean): boolean =>
  (coarse || portrait) && (choice === 0 ? coarse && portrait : choice === 1);
