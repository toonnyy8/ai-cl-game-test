// touch.test.ts <- tests/touch-test.lisp: the one-thumb recogniser (src/input/touch.ts), the rows of
// DUEL_MOBILE_DESIGN.md §3.2 as remapped on 2026-09-28 (§15), check for check.
import { describe, expect, it } from 'vitest';
import { TP_FLICK, TP_HOHO, TP_TAP, TP_TAP_HI, Touch, gestureConfig, type TouchEvent5 } from '../src/input/touch';

/** A recogniser at DPR 1: pad 16..276 x 600..794, chips O (220 548 r36) and AWAKEN (120 548, hold 300 ms). */
const fresh = () => new Touch().layout(1, [16, 600, 276, 794], [[220, 548, 36], [120, 548, 26]], [0, 300]);
const feed = (tr: Touch, now: number, ...ev: TouchEvent5[]) => tr.feed(ev, now);
const take = (tr: Touch) => tr.take();
const pulse = (tr: Touch, bit: number) => take(tr).pulseP(bit);

describe('touch recogniser', () => {
  it('TAP: one Quick pulse, live for one read, also a menu tap', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 104, 702, 30], [2, 0, 104, 702, 90]);
    expect(pulse(tr, TP_TAP)).toBe(true);
    expect(pulse(tr, TP_TAP)).toBe(false);
    expect(tr.tappedP()).toBe(true);
  });
  it('pulse latch: a frame with no read keeps the pulse pending', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [2, 0, 100, 700, 50]);
    feed(tr, 33);
    expect(pulse(tr, TP_TAP)).toBe(true);
  });
  it('REST: still for tap-ms = guard; the lift does nothing', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0]);
    expect(tr.restingP()).toBe(false);
    feed(tr, 125);
    expect(tr.restingP()).toBe(true);
    feed(tr, 140, [2, 0, 100, 700, 140]);
    expect(!tr.restingP() && tr.pend === 0).toBe(true);
  });
  it('FLICK down: Step + direction at the crossing, held', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 100, 712, 10], [1, 0, 100, 732, 30]);
    take(tr);
    expect(tr.pulseP(TP_FLICK)).toBe(true);
    expect(tr.flickDownP() && tr.sy() < -0.99 && Math.abs(tr.sx()) < 0.01).toBe(true);
    expect(tr.stepHeldP()).toBe(true);
  });
  it('a slow stroke is a drag, not a flick', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 112, 700, 20], [1, 0, 125, 700, 200], [1, 0, 140, 700, 260]);
    expect(pulse(tr, TP_FLICK)).toBe(false);
    expect(tr.sx() > 0.8 && !tr.stepHeldP()).toBe(true);
  });
  it('TAP ZONES: split at the middle, where the thumb went down decides', () => {
    const tr = fresh();
    expect(tr.splitY()).toBe(697);
    feed(tr, 16, [0, 0, 100, 650, 0], [2, 0, 100, 650, 50]);
    let l = take(tr).live;
    expect((l & TP_TAP_HI) !== 0 && (l & TP_TAP) === 0).toBe(true);
    feed(tr, 116, [0, 0, 100, 760, 100], [2, 0, 100, 760, 150]);
    l = take(tr).live;
    expect((l & TP_TAP) !== 0 && (l & TP_TAP_HI) === 0).toBe(true);
    feed(tr, 216, [0, 0, 100, 696.5, 200], [2, 0, 100, 696.5, 250]);
    expect(pulse(tr, TP_TAP_HI)).toBe(true);
    feed(tr, 316, [0, 0, 100, 697, 300], [2, 0, 100, 697, 350]);
    expect(pulse(tr, TP_TAP)).toBe(true);
    feed(tr, 416, [0, 0, 100, 601, 400], [2, 0, 100, 601, 450]);
    expect(pulse(tr, TP_TAP_HI)).toBe(true);
    feed(tr, 516, [0, 0, 100, 794, 500], [2, 0, 100, 794, 550]);
    expect(pulse(tr, TP_TAP)).toBe(true);
    feed(tr, 616, [0, 0, 100, 692, 600], [1, 0, 106, 700, 620], [2, 0, 106, 700, 650]);
    expect(pulse(tr, TP_TAP_HI)).toBe(true);
  });
  it('the tap-split knob moves the line', () => {
    const tr = new Touch(gestureConfig({ tapSplit: 0.25 })).layout(1, [16, 600, 276, 794]);
    feed(tr, 16, [0, 0, 100, 660, 0], [2, 0, 100, 660, 50]);
    expect(pulse(tr, TP_TAP)).toBe(true);
  });
  it.each(['JJJ', 'JJK', 'JKK', 'KKK', 'KKJ', 'KJJ'])('string route %s by taps', (route) => {
    const tr = fresh();
    const got = [...route].map((c, i) => {
      const ms = 200 * i, y = c === 'K' ? 640 : 750;
      feed(tr, ms + 60, [0, 0, 120, y, ms], [2, 0, 120, y, ms + 50]);
      const l = take(tr).live;
      return l === TP_TAP ? 'J' : l === TP_TAP_HI ? 'K' : '?';
    }).join('');
    expect(got).toBe(route);
  });
  it('FLICK UP = the forward dash: Step at the crossing, straight ahead, nothing on the lift', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 100, 688, 10], [1, 0, 100, 668, 30]);
    const l = take(tr).live;
    expect((l & TP_FLICK) !== 0 && (l & (TP_TAP | TP_TAP_HI)) === 0).toBe(true);
    expect(tr.sy() > 0.99 && tr.sx() === 0 && tr.stepHeldP() && !tr.flickDownP()).toBe(true);
    feed(tr, 90, [2, 0, 100, 668, 80]);
    expect(take(tr).live === 0 && !tr.stepHeldP()).toBe(true);
  });
  it('a long up-stroke: no stick while undecided, then Step held past the run ring', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 780, 0], [1, 0, 100, 768, 8], [1, 0, 99, 758, 16]);
    expect(tr.sy() === 0 && !tr.stepHeldP()).toBe(true);
    feed(tr, 33, [1, 0, 98, 750, 20], [1, 0, 94, 700, 32], [1, 0, 92, 670, 40], [1, 0, 90, 640, 48]);
    expect(pulse(tr, TP_FLICK)).toBe(true);
    expect(tr.stepHeldP() && tr.sy() > 0.9).toBe(true);
    feed(tr, 150, [2, 0, 90, 640, 140]);
    expect(!tr.stepHeldP() && take(tr).live === 0).toBe(true);
  });
  it('a slanted up-flick (50 deg) is straight ahead', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 200, 750, 0], [1, 0, 190, 742, 8], [1, 0, 175, 732, 16], [1, 0, 170, 725, 24], [2, 0, 170, 725, 60]);
    expect(pulse(tr, TP_FLICK) && tr.sx() === 0 && tr.sy() > 0.5).toBe(true);
  });
  it('past the up cone: a side flick keeps its direction', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 200, 750, 0], [1, 0, 188, 746, 8], [1, 0, 170, 740, 16]);
    expect(pulse(tr, TP_FLICK) && tr.sx() < -0.9).toBe(true);
  });
  it('a slow drag up still walks once the window closes (also on the clock)', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 100, 694, 40], [1, 0, 100, 688, 80]);
    expect(tr.sy()).toBe(0);
    feed(tr, 250, [1, 0, 100, 682, 120], [1, 0, 100, 676, 160], [1, 0, 100, 668, 240]);
    expect(tr.sy() > 0.6 && !tr.stepHeldP() && !pulse(tr, TP_FLICK)).toBe(true);
    feed(tr, 300);
    expect(tr.sy() > 0.6).toBe(true);
  });
  it('the clock alone ends the undecided phase', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 100, 686, 10]);
    feed(tr, 200);
    expect(tr.sy() > 0.2).toBe(true);
  });
  it('HOHO: rest, then an up-stroke when the game allows it', () => {
    const tr = fresh();
    tr.restUpOk = true;
    feed(tr, 16, [0, 0, 100, 700, 0]);
    feed(tr, 150);
    feed(tr, 166, [1, 0, 100, 688, 155], [1, 0, 100, 668, 165]);
    expect(pulse(tr, TP_HOHO)).toBe(true);
  });
  it('the dash otherwise; a fresh up-flick is the dash even when Hoho is allowed', () => {
    let tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0]);
    feed(tr, 150);
    feed(tr, 166, [1, 0, 100, 688, 155], [1, 0, 100, 668, 165], [2, 0, 100, 668, 180]);
    let l = take(tr).live;
    expect((l & TP_FLICK) !== 0 && (l & TP_HOHO) === 0).toBe(true);
    tr = fresh();
    tr.restUpOk = true;
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 100, 688, 10], [1, 0, 100, 668, 30]);
    l = take(tr).live;
    expect((l & TP_FLICK) !== 0 && (l & TP_HOHO) === 0).toBe(true);
  });
  it('any up-flick is a Hoho while the game says so (UP-HOHO)', () => {
    const tr = fresh();
    tr.upHoho = true;
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 100, 688, 10], [1, 0, 100, 668, 30]);
    const l = take(tr).live;
    expect((l & TP_HOHO) !== 0 && (l & TP_FLICK) === 0).toBe(true);
  });
  it('a spent flick (a burst): nothing more from the contact', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 600, 0], [1, 0, 100, 612, 10], [1, 0, 100, 632, 30]);
    take(tr);
    expect(tr.pulseP(TP_FLICK)).toBe(true);
    tr.spend();
    expect(!tr.pulseP(TP_FLICK) && tr.sy() === 0).toBe(true);
    feed(tr, 200, [1, 0, 100, 700, 60], [1, 0, 100, 760, 90], [1, 0, 100, 800, 120]);
    expect(!pulse(tr, TP_FLICK) && !tr.stepHeldP() && tr.sy() === 0).toBe(true);
  });
  it('DRAG far: Step held past the run ring, released inside 1.3 r; back to rest', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [1, 0, 110, 700, 40], [1, 0, 125, 700, 200], [1, 0, 140, 700, 330], [1, 0, 190, 700, 360]);
    expect(tr.stepHeldP() && !pulse(tr, TP_FLICK)).toBe(true);
    feed(tr, 380, [1, 0, 150, 700, 370]);
    expect(tr.stepHeldP()).toBe(false);
    feed(tr, 400, [1, 0, 103, 700, 390]);
    feed(tr, 520);
    expect(tr.restingP()).toBe(true);
  });
  it('CANCELED: never a tap; a second cancel or an unknown finger is harmless', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [3, 0, 100, 700, 40], [3, 0, 100, 700, 41], [3, 5, 0, 0, 42]);
    expect(!pulse(tr, TP_TAP) && !tr.tappedP() && tr.gid === -1).toBe(true);
  });
  it('focus lost: everything released', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [0, 1, 220, 548, 0]);
    feed(tr, 200);
    expect(tr.restingP() && tr.chipDownP(0)).toBe(true);
    feed(tr, 216, [4, -1, 0, 0, 210]);
    expect(!tr.restingP() && !tr.chipDownP(0)).toBe(true);
  });
  it('the latest contact in the pad wins; the old one\'s lift is ignored', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 100, 700, 0], [0, 1, 200, 700, 5], [2, 0, 100, 700, 40]);
    expect(pulse(tr, TP_TAP)).toBe(false);
    feed(tr, 60, [2, 1, 200, 700, 60]);
    expect(pulse(tr, TP_TAP)).toBe(true);
  });
  it('chips: held while the finger slides off, released on lift; the hold chip needs 300 ms', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 220, 548, 0], [1, 0, 300, 450, 10]);
    expect(tr.chipDownP(0) && tr.chipHitP(0) && tr.gid === -1).toBe(true);
    feed(tr, 40, [2, 0, 300, 450, 30]);
    expect(tr.chipDownP(0)).toBe(false);
    feed(tr, 60, [0, 2, 120, 548, 50]);
    expect(tr.chipDownP(1)).toBe(false);
    feed(tr, 360);
    expect(tr.chipDownP(1)).toBe(true);
  });
  it('chips inside the pad win their hit circles; an up-flick crossing a chip is still the dash', () => {
    const tr = new Touch().layout(1, [16, 364, 358, 794], [[318, 564, 26]]);
    feed(tr, 16, [0, 0, 318, 597, 0]);
    expect(tr.chipDownP(0) && tr.gid === -1).toBe(true);
    feed(tr, 40, [2, 0, 318, 597, 30]);
    expect(take(tr).live).toBe(0);
    feed(tr, 60, [0, 1, 318, 600, 50], [1, 1, 318, 588, 58], [1, 1, 318, 568, 66], [1, 1, 318, 540, 74], [2, 1, 318, 540, 100]);
    const l = take(tr).live;
    expect((l & TP_FLICK) !== 0 && tr.sx() === 0 && !tr.chipDownP(0)).toBe(true);
    feed(tr, 200, [0, 2, 280, 564, 190], [1, 2, 268, 564, 198], [1, 2, 250, 564, 206]);
    expect(pulse(tr, TP_FLICK) && tr.stepHeldP()).toBe(true);
  });
  it('a touch outside the pad and the chips starts no gesture (still a menu tap)', () => {
    const tr = fresh();
    feed(tr, 16, [0, 0, 50, 100, 0], [2, 0, 50, 100, 40]);
    expect(!pulse(tr, TP_TAP) && tr.tappedP()).toBe(true);
  });
});
