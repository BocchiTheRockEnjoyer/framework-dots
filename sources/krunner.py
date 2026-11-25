"""Dotted search field and list highlight for the Plasma theme. Usage: mk.py OUTDIR
Colours come from the colour scheme, so light/dark and the accent follow by themselves."""
import math, sys
O = sys.argv[1]; Q = .5
CSS = '<defs><style id="current-color-scheme" type="text/css">.ColorScheme-Text{color:#fcfcfc;}.ColorScheme-Highlight{color:#808080;}.ColorScheme-Background{color:#1a1a1a;}</style></defs>'
def frame(pre, x0, y0, b, mid, cls, fill, line, dot, r):
    """Nine-piece frame: corner b, solid outline, dot grid inside (one dot per 4px tile)."""
    pid = f'{pre}-' if pre else ''; o = []
    def piece(name, x, y, w, h, body): o.append(f'<g id="{pid}{name}"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#000" fill-opacity="0"/>{body}</g>')
    C = f'class="ColorScheme-{cls}" fill="currentColor"'
    def rect(x, y, w, h, a): return f'<rect {C} fill-opacity="{a}" x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}"/>' if a and w > 0 and h > 0 else ''
    g = 4; X = [x0, x0 + b + g, x0 + b + g + mid + g]; Y = [y0, y0 + b + g, y0 + b + g + mid + g]; r = min(r, b)
    def corner(name, x, y, fx, fy):
        # drawn for the top left, then mirrored
        t = f'translate({x + (b if fx else 0)},{y + (b if fy else 0)}) scale({-1 if fx else 1},{-1 if fy else 1})'
        body = f'<path {C} fill-opacity="{fill}" d="M0 {b}V{r}A{r} {r} 0 0 1 {r} 0H{b}V{b}Z"/>' if fill else ''
        if line: i = r - 1; body += f'<path {C} fill-opacity="{line}" d="M0 {b}V{r}A{r} {r} 0 0 1 {r} 0H{b}V1H{r}A{i} {i} 0 0 0 1 {r}V{b}Z"/>'
        piece(name, x, y, b, b, f'<g transform="{t}">{body}</g>')
    corner('topleft', X[0], Y[0], 0, 0); corner('topright', X[2], Y[0], 1, 0); corner('bottomleft', X[0], Y[2], 0, 1); corner('bottomright', X[2], Y[2], 1, 1)
    piece('top', X[1], Y[0], mid, b, rect(X[1], Y[0], mid, b, fill) + rect(X[1], Y[0], mid, 1, line))
    piece('bottom', X[1], Y[2], mid, b, rect(X[1], Y[2], mid, b, fill) + rect(X[1], Y[2] + b - 1, mid, 1, line))
    piece('left', X[0], Y[1], b, mid, rect(X[0], Y[1], b, mid, fill) + rect(X[0], Y[1], 1, mid, line))
    piece('right', X[2], Y[1], b, mid, rect(X[2], Y[1], b, mid, fill) + rect(X[2] + b - 1, Y[1], 1, mid, line))
    dots = ''.join(f'<circle {C} fill-opacity="{dot}" cx="{X[1] + 2 + 4 * i}" cy="{Y[1] + 2 + 4 * j}" r=".8"/>' for i in range(mid // 4) for j in range(mid // 4)) if dot else ''
    piece('center', X[1], Y[1], mid, mid, rect(X[1], Y[1], mid, mid, fill) + dots)
    return ''.join(o)
def hints(pre, x, y, m):
    return ''.join(f'<rect id="{pre}-hint-{s}-margin" x="{x + 14 * i}" y="{y}" width="{m}" height="{m}" fill="#f0f"/>' for i, s in enumerate(('top', 'bottom', 'left', 'right')))
def save(n, body): open(f'{O}/{n}.svg', 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300">{CSS}{body}<rect id="hint-tile-center" x="380" y="280" width="4" height="4" fill="#f0f"/></svg>\n')
VB, LB, LM, FM = (int(a) for a in sys.argv[2:6])      # Breeze's own border sizes, so nothing moves
save('viewitem', frame('normal', 0, 0, VB, 16, 'Text', 0, 0, 0, 5) + frame('hover', 100, 0, VB, 16, 'Highlight', .10, .75, .30, 5)
     + frame('selected', 0, 100, VB, 16, 'Highlight', .14, .85, .34, 5) + frame('selected+hover', 100, 100, VB, 16, 'Highlight', .20, 1, .40, 5))
save('lineedit', frame('base', 0, 0, LB, 16, 'Text', .05, .28, .07, 5) + hints('base', 0, 90, LM) + frame('hover', 100, 0, LB, 16, 'Highlight', 0, .6, 0, 5) + hints('hover', 100, 90, LM)
     + frame('focus', 0, 120, LB, 16, 'Highlight', 0, .95, 0, 5) + hints('focus', 0, 210, LM) + frame('focusframe', 100, 120, 7, 16, 'Highlight', 0, .95, 0, 7) + hints('focusframe', 100, 210, FM)
     + '<rect id="hint-focus-over-base" x="360" y="280" width="4" height="4" fill="#f0f"/>')
