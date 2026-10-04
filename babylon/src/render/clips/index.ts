// Per-character move -> clip tables (render/clips/<char>.ts); anim.ts asks the fighter's character first and falls back
// to its generic mapping (moveClipName).
import type { Move } from '../../sim/kit';
import type { Clip, PoseSpec } from '../pose';
import type { ClipName } from '../anim';
import type { Fighter } from '../../sim/types';
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
  /** A bespoke clip for fighter F's current frame of MV, or null (clipFor / the generic mapping). A bare Clip is
   *  sampled at u (pose.ts phase) in the main phase and at f.hold (frames) in the pre-strike phases (hold / aura / dash /
   *  follow); [clip, x] is sampled at x. */
  move?(mv: Move, f: Fighter): Clip | [Clip, number] | null;
  /** FORM's own stance poses and locomotion (walk keyed 0..4 = a stride pair, run 0..2), or null: the defaults. */
  stance?(form: string): Stance | null;
}
export interface Stance { idle?: PoseSpec; guard?: PoseSpec; guardHit?: PoseSpec; walk?: Clip; run?: Clip; step?: PoseSpec; hoho?: PoseSpec }
export const CLIPS: Record<string, CharClips> = { yamamoto: yama, kenpachi: ken, rukia, ichigo, senjumaru: senju };
