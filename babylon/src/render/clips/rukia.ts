// Rukia's move -> clip table (none yet: the generic mapping) and idle (default).
import type { Move } from '../../sim/kit';
import type { ClipName } from '../anim';

export function clipFor(_c: string, _mv: Move): ClipName | null { return null; }
