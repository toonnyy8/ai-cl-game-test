#!/usr/bin/env python3
"""glyph-bake.py — bake the brush glyphs SOUL DUEL needs from the Yuji Syuku font (SIL OFL 1.1) into
duel/lisp/glyphs.lisp (docs/style/STYLE_STORM_DESIGN.md §4.4). Build-time only: the game loads no font file; the
output is committed. Needs fontTools and skia-pathops (a venv, e.g. `uv venv v && uv pip install --python v/bin/python
fonttools skia-pathops`).

  v/bin/python tools/glyph-bake.py FONT.ttf              writes duel/lisp/glyphs.lisp

Per glyph: the outline with its overlaps removed (pathops), the curves flattened (chord error <= FLAT font
units), simplified (Douglas-Peucker, SIMPLIFY units), each hole bridged into the outer contour that holds it
(a zero-width cut to the nearest vertex it can see), so a glyph is a few simple polygons. They are written
as integer coordinates in 1/1000 em, y down from the top of the ideographic em box, each polygon wound
positive in that frame. duel/lisp/brush.lisp ear-clips them into triangles at load.
To add a glyph: put it in CHARS, re-run, commit glyphs.lisp.
"""
import math, sys
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen
import pathops

CHARS = ("卍解残火の太刀野晒呑め、鬼魂城郭炎上天地灰尽旭日刃獄衣十万億死大葬陣東西南北撫斬勝"
         "山本元柳斎重國更木剣八不知松明俺斬決着時間切光焦熱攻"
         "腕片盾殴飛噛千切真二草鹿"
         "朽ルキア月白初舞霞罸絶対零度漣這縄霜閃氷震凍結次参縛柱"
         "ぶったるてみろよにれねえもんは"
         "リジェ・バロ物貫通三連廉脚翼斉射四孔裁き筋神喇叭"   # Lille Barro (docs/duel/DUEL_LILLE.md)
         "ABCDEFGHIJKLMNOPQRSTUVWXYZ.,!-:'")
OUT = "duel/lisp/glyphs.lisp"
FLAT, SIMPLIFY = 1.0, 2.5         # font units (1000 per em): ~0.5 px on a 200 px glyph
TOP = 880                         # the ideographic em box: 880 above the baseline .. 120 below


class Flatten(BasePen):
    """Record contours as point lists, flattening the curves."""
    def __init__(self, gs):
        super().__init__(gs); self.contours = []; self.cur = None

    def _moveTo(self, p): self.cur = [p]
    def _lineTo(self, p): self.cur.append(p)

    def _curve(self, pts, f):
        p0 = self.cur[-1]; n = max(1, math.ceil(math.sqrt(sum(math.dist(a, b) for a, b in zip([p0] + pts, pts)) / (8 * FLAT))))
        for i in range(1, n + 1): self.cur.append(f(p0, *pts, i / n))

    def _qCurveToOne(self, a, b):
        self._curve([a, b], lambda p0, p1, p2, t: tuple((1 - t) ** 2 * p0[k] + 2 * (1 - t) * t * p1[k] + t * t * p2[k] for k in (0, 1)))

    def _curveToOne(self, a, b, c):
        self._curve([a, b, c], lambda p0, p1, p2, p3, t: tuple((1 - t) ** 3 * p0[k] + 3 * (1 - t) ** 2 * t * p1[k]
                                                               + 3 * (1 - t) * t * t * p2[k] + t ** 3 * p3[k] for k in (0, 1)))

    def _closePath(self):
        if self.cur and len(self.cur) > 2: self.contours.append(self.cur)
        self.cur = None
    _endPath = _closePath


def dp(pts, eps):
    """Douglas-Peucker on a closed ring (split at the two farthest-apart points)."""
    def rec(a):
        if len(a) < 3: return a
        (x0, y0), (x1, y1) = a[0], a[-1]; L = math.dist(a[0], a[-1]) or 1e-9
        d = [abs((x1 - x0) * (y0 - y) - (x0 - x) * (y1 - y0)) / L for x, y in a[1:-1]]
        i = max(range(len(d)), key=d.__getitem__)
        return rec(a[:i + 2])[:-1] + rec(a[i + 1:]) if d[i] > eps else [a[0], a[-1]]
    j = max(range(len(pts)), key=lambda k: math.dist(pts[0], pts[k]))
    r = rec(pts[:j + 1])[:-1] + rec(pts[j:] + [pts[0]])[:-1]
    return r if len(r) >= 3 else pts


def area(p): return 0.5 * sum(p[i - 1][0] * p[i][1] - p[i][0] * p[i - 1][1] for i in range(len(p)))


def inside(pt, poly):
    x, y = pt; c = False
    for i in range(len(poly)):
        (ax, ay), (bx, by) = poly[i - 1], poly[i]
        if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay): c = not c
    return c


def cross(a, b, c, d):
    """Do segments ab and cd properly intersect (not at shared end points)?"""
    def o(p, q, r): return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    if a in (c, d) or b in (c, d): return False
    return (o(a, b, c) > 0) != (o(a, b, d) > 0) and (o(c, d, a) > 0) != (o(c, d, b) > 0)


def bridge(outer, holes):
    """Merge each hole into OUTER with a zero-width cut from its rightmost vertex to the nearest outer vertex
    that the cut does not cross any edge to (holes taken right to left, so later cuts see earlier ones)."""
    poly = list(outer)
    for h in sorted(holes, key=lambda h: -max(x for x, _ in h)):
        mi = max(range(len(h)), key=lambda k: h[k][0]); m = h[mi]
        edges = [(poly[i - 1], poly[i]) for i in range(len(poly))] + [(q[i - 1], q[i]) for q in holes for i in range(len(q))]
        once = {q for q in poly if poly.count(q) == 1}           # not an earlier cut's end: its wedge is ambiguous
        best = min((k for k in range(len(poly)) if poly[k] in once and not any(cross(m, poly[k], a, b) for a, b in edges)),
                   key=lambda k: math.dist(m, poly[k]))
        ring = h[mi:] + h[:mi]
        poly = poly[:best + 1] + ring + [m] + poly[best:]
    return poly


def glyph(gs, name):
    p = pathops.Path(); gs[name].draw(p.getPen()); p.simplify()       # overlaps removed, windings made consistent
    f = Flatten(gs); p.draw(f)
    rings = [[(round(x), round(TOP - y)) for x, y in dp(c, SIMPLIFY)] for c in f.contours]
    rings = [[q for i, q in enumerate(r) if q != r[i - 1]] for r in rings]
    rings = [r for r in rings if len(r) >= 3 and abs(area(r)) > 4]
    if not rings: return []
    sign = 1 if area(max(rings, key=lambda r: abs(area(r)))) > 0 else -1     # the outers' winding (y down)
    outers = [r if sign > 0 else r[::-1] for r in rings if area(r) * sign > 0]
    holes = [r if sign > 0 else r[::-1] for r in rings if area(r) * sign < 0]
    own = {i: [] for i in range(len(outers))}
    for h in holes:                                                  # the smallest outer that holds it
        ks = [i for i, o in enumerate(outers) if inside((h[0][0] + 0.01, h[0][1] + 0.013), o)]
        if ks: own[min(ks, key=lambda i: abs(area(outers[i])))].append(h)
    return [bridge(o, own[i]) for i, o in enumerate(outers)]


def main(font):
    f = TTFont(font); cmap = f.getBestCmap(); gs = f.getGlyphSet(); hm = f["hmtx"]
    missing = [c for c in CHARS if ord(c) not in cmap]
    if missing: sys.exit(f"not in the font: {''.join(missing)}")
    out = [";;;; glyphs.lisp — GENERATED by tools/glyph-bake.py (do not edit): the brush glyphs of the captions, from",
           ";;;; the font Yuji Syuku (https://github.com/Kinutafontfactory/Yuji).",
           ";;;; Copyright 2021 The Yuji Project Authors (https://github.com/Kinutafontfactory/Yuji).",
           ";;;; This Font Software is licensed under the SIL Open Font License, Version 1.1; the licence text is in",
           ";;;; duel/FONT-LICENSE-YujiSyuku.txt. These outlines are a converted subset of the font (a Modified Version",
           ";;;; under the OFL, not a font file); the Reserved Font Name is not used for them.",
           ";;;; Per glyph: (CODE ADVANCE POLYGON...), a polygon a flat list x0 y0 x1 y1 ... in 1/1000 em, y down from the",
           ";;;; top of the em box, wound positive (holes already bridged in). brush.lisp triangulates them at load.",
           "(in-package :duel)", "", "(defparameter *glyph-outlines*", "  '("]
    npts = 0
    for c in dict.fromkeys(CHARS):
        polys = glyph(gs, cmap[ord(c)]); npts += sum(len(p) for p in polys)
        body = " ".join("(" + " ".join(f"{x} {y}" for x, y in p) + ")" for p in polys)
        out.append(f"    ({ord(c)} {hm[cmap[ord(c)]][0]} {body}) ; {c}")
    out.append("    )\n  \"Brush glyph outlines by char code (tools/glyph-bake.py).\")")
    open(OUT, "w").write("\n".join(out) + "\n")
    print(f"{OUT}: {len(dict.fromkeys(CHARS))} glyphs, {npts} points")


if __name__ == "__main__":
    main(sys.argv[1])
