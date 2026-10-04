// The body registry: each roster character's CharBody (render/bodies/<char>.ts), and the body for a fighter's form.
import type { BodySpec, CharBody } from '../body';
import { yama } from './yama';
import { ken } from './ken';
import { rukia } from './rukia';
import { ichigo } from './ichigo';
import { senju } from './senju';

export const BODIES: Record<string, CharBody> = { yamamoto: yama, kenpachi: ken, rukia, ichigo, senjumaru: senju };

/** CHARACTER's body in FORM: the base CharBody with that form's variant folded in, and a cache key per (character,
 *  variant) (`char:base` when the form has no variant). */
export function bodyFor(character: string, form: string): { key: string; body: CharBody } {
  const base = BODIES[character] ?? BODIES.kenpachi, v = base.variant(form);
  if (!v) return { key: `${character}:base`, body: base };
  return { key: `${character}:${form}`, body: { ...base, ...v, spec: { ...base.spec, ...v.spec } as BodySpec } };
}
