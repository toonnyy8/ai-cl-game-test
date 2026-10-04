// Per-character move -> clip tables (render/clips/<char>.ts); anim.ts asks the fighter's character first and falls back
// to its generic mapping (moveClipName).
import type { Move } from '../../sim/kit';
import type { Clip, PoseSpec } from '../pose';
import type { ClipName } from '../anim';
import * as yama from './yama';
import * as ken from './ken';
import * as rukia from './rukia';
import * as ichigo from './ichigo';
import * as senju from './senju';

export interface CharClips {
  /** The clip for move MV whose art-contract clip name is CLIP (clip2 outside SP moves), or null: the generic mapping. */
  clipFor(clip: string, mv: Move): ClipName | null;
  /** The character's idle stance (default P.idleKen). */
  idle?: PoseSpec;
  /** Per form (fighter.form): its idle (overrides IDLE), guard and run cycle (keys over [0, 2]), or null: the defaults. */
  stance?(form: string): { idle?: PoseSpec; guard?: PoseSpec; run?: Clip } | null;
  /** A bespoke clip for MV in FORM keyed in phase u (0 start, 1 frame S, 2 end of active, 3 end), or null: clipFor's. */
  clip?(mv: Move, form: string): Clip | null;
}
export const CLIPS: Record<string, CharClips> = { yamamoto: yama, kenpachi: ken, rukia, ichigo, senjumaru: senju };
