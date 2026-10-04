// Yamamoto's move -> clip table and idle.
import type { Move } from '../../sim/kit';
import type { ClipName } from '../anim';
import { P } from '../pose';

export const idle = P.idleYama;
export function clipFor(c: string, mv: Move): ClipName | null {
  if (mv.hits.length > 1) return null;
  if (c.includes('taimatsu') || c.includes('shiranui') || c.includes('ikkotsu')) return 'palm';
  if (c.includes('enjo')) return 'thrust';
  return null;
}
