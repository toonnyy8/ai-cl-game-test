// menus.ts: the DOM menus over the canvas (#ui): a page = a title, rows and notes, rebuilt from its builder after every
// action, so what is shown is always the flow's state. Rows answer the keyboard / pads (flow.ts calls nav) and taps /
// clicks (a row: its action, else its option's next value; the < > arrows: the option back / on). A row may instead hold
// CELLS (CONTROLS: one per device column). The look is plain modern UI; the behaviour is flow.lisp's MENU-NAV.
export interface Cell { text: string; on?: boolean; act: () => void }
export interface Row {
  label: string; value?: string; note?: string; cls?: string;
  act?: () => void; dir?: (d: number) => void; cells?: Cell[];
}
export interface Page {
  title: string; sub?: string; cls?: string; html?: string; rows: Row[]; note?: string; foot?: string;
  back?: () => void; tap?: () => void;            // TAP: a tap / click anywhere on the page (the title screen)
  col?: number;                                   // the selected cell column of the selected row
}

import { uiSfx } from '../audio';

const root = document.getElementById('ui') as HTMLDivElement;
let builder: (() => Page) | null = null;
let page: Page | null = null;
export let sel = 0;

/** Show the page BUILDER makes (null: hide the menus), the cursor on ROW. */
export function show(b: (() => Page) | null, row = 0): void { builder = b; sel = row; refresh(); }
export const shown = (): boolean => builder !== null;
export function setSel(i: number): void { sel = i; refresh(); }

function el<K extends keyof HTMLElementTagNameMap>(tag: K, cls: string, text = ''): HTMLElementTagNameMap[K] {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text) e.textContent = text;
  return e;
}
/** Run an action from a pointer: the action, then the page again (unless it switched pages itself). */
function run(fn: () => void, click: 'confirm' | 'select' = 'confirm'): (ev: Event) => void {
  return (ev) => { ev.stopPropagation(); uiSfx(click); const b = builder; fn(); if (builder === b) refresh(); };
}

/** Rebuild the page from its builder (after any state change). */
export function refresh(): void {
  root.replaceChildren();
  page = builder ? builder() : null;
  root.hidden = !page;
  if (!page) return;
  const p = page;
  sel = Math.max(0, Math.min(sel, p.rows.length - 1));
  const box = el('div', `page ${p.cls ?? ''}`);
  if (p.tap) box.addEventListener('click', run(p.tap));
  box.append(el('h1', 'title', p.title));
  if (p.sub) box.append(el('div', 'sub', p.sub));
  if (p.html) { const h = el('div', 'extra'); h.innerHTML = p.html; box.append(h); }
  const list = el('div', 'rows');
  p.rows.forEach((r, i) => {
    const row = el('div', `row ${r.cls ?? ''} ${i === sel ? 'on' : ''}`);
    row.append(el('span', 'label', r.label));
    if (r.cells) {
      const cs = el('span', 'cells');
      r.cells.forEach((c, j) => {
        const cell = el('span', `cell ${i === sel && j === (p.col ?? -1) ? 'on' : ''} ${c.on ? 'wait' : ''}`, c.text);
        cell.addEventListener('click', run(() => { sel = i; p.col = j; c.act(); }));
        cs.append(cell);
      });
      row.append(cs);
    } else if (r.value !== undefined) {
      const v = el('span', 'value');
      if (r.dir) {
        const l = el('span', 'arrow', '‹'), rr = el('span', 'arrow', '›');
        l.addEventListener('click', run(() => { sel = i; r.dir!(-1); }, 'select'));
        rr.addEventListener('click', run(() => { sel = i; r.dir!(1); }, 'select'));
        v.append(l, el('span', 'opt', r.value), rr);
      } else v.append(el('span', 'opt', r.value));
      row.append(v);
    }
    if (!r.cells) row.addEventListener('click', run(() => { sel = i; (r.act ?? (() => r.dir?.(1)))(); }));
    list.append(row);
  });
  box.append(list);
  const note = p.rows[sel]?.note ?? p.note;
  if (note) box.append(el('div', 'note', note));
  if (p.foot) box.append(el('div', 'foot', p.foot));
  root.append(box);
  (list.children[sel] as HTMLElement | undefined)?.scrollIntoView?.({ block: 'nearest' });
}

export type Nav = 'up' | 'down' | 'left' | 'right' | 'confirm' | 'back';
/** A menu key: up / down the cursor, left / right the selected option (or cell column), confirm its action, back. */
export function nav(a: Nav): void {
  if (!page) return;
  const p = page, b = builder, n = p.rows.length, r = p.rows[sel];
  if (a === 'back' ? p.back : a === 'confirm' ? p.tap || r : a === 'up' || a === 'down' ? n > 1 : r?.dir || r?.cells)   // flow.lisp's clicks
    uiSfx(a === 'back' ? 'back' : a === 'confirm' ? 'confirm' : 'select');
  if (a === 'up' || a === 'down') sel = n ? (((sel + (a === 'up' ? -1 : 1)) % n) + n) % n : 0;
  else if (a === 'back') p.back?.();
  else if (a === 'confirm') {
    if (p.tap) p.tap();
    else if (r?.cells) r.cells[p.col ?? 0]?.act();
    else if (r) (r.act ?? (() => r.dir?.(1)))();
  } else if (r?.dir) r.dir(a === 'left' ? -1 : 1);
  if (builder === b) refresh();
}
