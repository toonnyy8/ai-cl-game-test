// Per-character move -> clip tables (render/clips/<char>.ts); anim.ts asks the fighter's character first and falls back
// to its generic mapping (moveClipName).
import type { Move } from '../../sim/kit';
import type { PoseSpec } from '../pose';
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
}
export const CLIPS: Record<string, CharClips> = { yamamoto: yama, kenpachi: ken, rukia, ichigo, senjumaru: senju };
