// Kenpachi's move -> clip table and idle.
import type { Move } from '../../sim/kit';
import type { ClipName } from '../anim';
import { P } from '../pose';

export const idle = P.idleKen;
export function clipFor(c: string, mv: Move): ClipName | null {
  if (mv.hits.length > 1) return null;
  if (c.endsWith('q3')) return 'spin';
  if (c.endsWith('f1')) return 'heavy';
  if (c.includes('buttagiru')) return 'leap';
  if (c.includes('shoulder')) return 'shoulder';
  if (c.includes('charge')) return 'thrust';
  return null;
}
