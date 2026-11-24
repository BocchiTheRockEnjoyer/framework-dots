#!/usr/bin/env python3
"""Builds FD Dots from Doto (SIL OFL 1.1, https://github.com/oliverlalan/Doto).
Needs fontTools. Usage: build-fd-dots.py 'Doto[ROND,wght].ttf' FDDots.ttf
Changes: one fixed weight with round dots, two-dot colon, rounded-box zero, narrower colon and space."""
import sys
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen
f = instantiateVariableFont(TTFont(sys.argv[1]), {"wght": 900, "ROND": 100})
cm, gs, g = f.getBestCmap(), f.getGlyphSet(), f["glyf"]
rec = DecomposingRecordingPen(gs); gs[cm[ord("°")]].draw(rec)
dot = []
for op in rec.value:
    dot.append(op)
    if op[0] == "closePath": break
pts = [p for _, a in dot for p in a if p]
cx = (min(p[0] for p in pts) + max(p[0] for p in pts)) / 2
cy = (min(p[1] for p in pts) + max(p[1] for p in pts)) / 2
def build(ch, cells, adv=None):
    n = cm[ord(ch)]; pen = TTGlyphPen(None)
    for x, y in cells:
        t = TransformPen(pen, (1, 0, 0, 1, x - cx, y - cy))
        for op, a in dot: getattr(t, op)(*a)
    g[n] = pen.glyph(); g[n].recalcBounds(g); f["hmtx"][n] = (adv or f["hmtx"][n][0], g[n].xMin)
build(":", [(100, 150), (100, 550)], 300)
build("0", [(x, y) for x in (150, 250, 350) for y in (50, 650)] + [(x, y) for x in (50, 450) for y in (150, 250, 350, 450, 550)])
f["hmtx"][cm[32]] = (350, 0)
f["post"].isFixedPitch = 0
for r in f["name"].names:
    if r.nameID in (1, 4, 16): r.string = "FD Dots"
    elif r.nameID in (2, 17): r.string = "Regular"
    elif r.nameID == 6: r.string = "FDDots-Regular"
    elif r.nameID == 3: r.string = "FDDots-Regular (from Doto)"
f["OS/2"].usWeightClass = 400
f["OS/2"].fsSelection = (f["OS/2"].fsSelection & ~0x21) | 0x40
f["head"].macStyle = 0
f.save(sys.argv[2])
