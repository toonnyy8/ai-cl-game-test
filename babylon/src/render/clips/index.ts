// Per-character move -> clip tables (render/clips/<char>.ts); anim.ts asks the fighter's character first and falls back
// to its generic mapping (moveClipName).
import type { Move } from '../../sim/kit';
import type { Clip, PoseSpec } from '../pose';
import type { Fighter } from '../../sim/types';
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
  /** The idle stance of FORM (overrides idle; undefined: idle). */
  idleFor?(form: string): PoseSpec | undefined;
  /** Guard, its recoil and the run cycle (keys 0..2), defaults P.guard / P.guardHit / the generic run. */
  guard?: PoseSpec; guardHit?: PoseSpec; run?: Clip;
  /** A bespoke clip for the current frame of move MV in any phase (hold / aura / dash / follow / main): [clip, x], the
   *  clip sampled at x (main: phase(mv, f.sf).u); null: clipFor / the generic mapping. IDLE: the form's stance. */
  move?(mv: Move, f: Fighter, idle: PoseSpec): [Clip, number] | null;
}
export const CLIPS: Record<string, CharClips> = { yamamoto: yama, kenpachi: ken, rukia, ichigo, senjumaru: senju };
