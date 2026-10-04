// keyboard.ts: the raw keyboard (KeyboardEvent.code names): keys held now, and the presses since the last frame. What a
// key means (P1 / P2 bindings, menus) is bindings.ts'. The vpad READERS run inside the fixed step (match.ts pilotRead).
const down = new Set<string>();
let presses: string[] = [];
/** Keys whose browser default (scrolling, find-as-you-type) is suppressed: everything but the F keys and modified chords. */
const keep = (e: KeyboardEvent) => /^F\d+$/.test(e.code) || e.ctrlKey || e.metaKey;

addEventListener('keydown', (e) => {
  if (!e.repeat) presses.push(e.code);
  down.add(e.code);
  if (!keep(e)) e.preventDefault();
});
addEventListener('keyup', (e) => down.delete(e.code));
addEventListener('blur', () => down.clear());

export const keyDown = (code: string): boolean => down.has(code);
/** Key codes pressed since the last call. */
export function takeKeyPresses(): string[] { const p = presses; presses = []; return p; }
