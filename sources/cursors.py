"""Draws the Framework Dots cursor theme: white dots on a black shape. Usage: mk.py OUTDIR"""
import math, os, shutil, struct, sys, zlib
OUT = sys.argv[1]; SIZES = (24, 30, 32, 36, 40, 48, 60, 64, 72, 96)
T = lambda s: [r for r in s.split()]
A = T("#....... ##...... ###..... ####.... #####... ######.. #######. ######## #####... ##.##... #..##... ....##..")
S = {}          # name: (rows, hotspot col, hotspot row)
def add(n, rows, hx, hy):
    w = max(map(len, rows)); S[n] = ([r.ljust(w, ".") for r in rows], hx, hy)
def flip(rows): w = max(map(len, rows)); return [r.ljust(w, ".")[::-1] for r in rows]
def turn(rows): w = max(map(len, rows)); R = [r.ljust(w, ".") for r in rows]; return ["".join(R[y][x] for y in range(len(R))) for x in range(w)]
def badge(rows, b, x, y):
    h = max(len(rows), y + len(b)); w = max(max(map(len, rows)), x + max(map(len, b)))
    g = [list((rows[i] if i < len(rows) else "").ljust(w, ".")) for i in range(h)]
    for j, r in enumerate(b):
        for i, c in enumerate(r):
            if c == "#": g[y + j][x + i] = "#"
    return ["".join(r) for r in g]
add("default", A, 0, 0); add("right_ptr", flip(A), 7, 0)
add("help", badge(A, T("###. ...# .##. .... .#.."), 8, 0), 0, 0)
add("context-menu", badge(A, T("##### ..... ##### ..... #####"), 8, 0), 0, 0)
add("copy", badge(A, T("..#.. ..#.. ##### ..#.. ..#.."), 7, 7), 0, 0)
add("alias", badge(A, T(".#### ...## ..#.# .#..# #...."), 7, 7), 0, 0)
add("pointer", T("...##..... ...##..... ...##..... ...##..... ...####... ...######. ##.####### ########## .######### ..######## ..#######. ...######."), 3.5, 0)
add("openhand", T("....#.#.... ..#.#.#.#.. ..#.#.#.#.. ..#.#.#.#.. ..#######.. #.#######.. #########.. .########.. ..#######.. ...#####..."), 5, 5)
add("dnd-move", T("..#.#.#.#.. ..#######.. ..#######.. #.#######.. #########.. .########.. ..#######.. ...#####..."), 5, 4)
add("text", T("##.## ..#.. ..#.. ..#.. ..#.. ..#.. ..#.. ..#.. ..#.. ..#.. ##.##"), 2, 5)
add("vertical-text", turn(S["text"][0]), 5, 2)
add("crosshair", T(".....#..... .....#..... .....#..... .....#..... ........... ####...#### ........... .....#..... .....#..... .....#..... .....#....."), 5, 5)
add("cell", T("....###.... ....###.... ....###.... ....###.... ########### ########### ########### ....###.... ....###.... ....###.... ....###...."), 5, 5)
H = T("...#.....#... ..##.....##.. .###########. ..##.....##.. ...#.....#...")
H = [r[1:-1] for r in H]
add("size_hor", H, 5, 2); add("size_ver", turn(H), 2, 5)
D = T("#####.... ###...... #.##..... #..##.... #...#...# ....##..# .....##.# ......### ....#####")
add("size_fdiag", D, 4, 4); add("size_bdiag", flip(D), 4, 4)
add("col-resize", T("....#.#.... ..#.#.#.#.. .##.#.#.##. ###.#.#.### .##.#.#.##. ..#.#.#.#.. ....#.#...."), 5, 3); add("row-resize", turn(S["col-resize"][0]), 3, 5)
add("fleur", T(".....#..... ....###.... .....#..... .....#..... .#...#...#. ########### .#...#...#. .....#..... .....#..... ....###.... .....#....."), 5, 5)
add("not-allowed", T("...#####... ..#.....#.. .#.....#.#. #.....#...# #....#....# #....#....# #...#.....# .#.#.....#. ..#.....#.. ...#####..."), 5, 4.5)
add("no-drop", badge(A, T(".###. #..## #.#.# ##..# .###."), 7, 7), 0, 0)
add("up-arrow", T("...#... ..###.. .#####. ####### ..###.. ..###.. ..###.. ..###.. ..###.. ..###.."), 3, 0)
add("down-arrow", S["up-arrow"][0][::-1], 3, 9); add("left-arrow", turn(S["up-arrow"][0]), 0, 3); add("right-arrow", flip(S["left-arrow"][0]), 9, 3)
add("zoom-in", T("..####..... .#....#.... #..##..#... #.####.#... #..##..#... .#....#.... ..#####.... ......##... .......##.. ........##."), 3.5, 3)
add("zoom-out", T("..####..... .#....#.... #......#... #.####.#... #......#... .#....#.... ..#####.... ......##... .......##.. ........##."), 3.5, 3)
add("color-picker", T("........##. .......#### ......####. ...#.###... ...####.... ....###.... ...##.##... ..##....... .##........ ##......... #.........."), 0, 10)
add("pencil", T("........##. .......#### ......####. .....###... ....###.... ...###..... ..###...... .###....... ##......... #.........."), 0, 9)
add("x-cursor", T("##.....## ###...### .###.###. ..#####.. ...###... ..#####.. .###.###. ###...### ##.....##"), 4, 4)
RING = [(5 + 4.4 * math.cos(2 * math.pi * k / 10 - math.pi / 2), 5 + 4.4 * math.sin(2 * math.pi * k / 10 - math.pi / 2)) for k in range(10)]
FR = 20
def dots(name, f):
    """(x, y, brightness) for each dot."""
    if name == "wait": return [(x, y, max(.16, 1 - ((f / 2 - k) % 10) / 7)) for k, (x, y) in enumerate(RING)]
    if name == "progress":
        p = [(x, y, 1) for y, r in enumerate(A) for x, c in enumerate(r) if c == "#"]
        return p + [(9.4 + (x - 5) * .52, 9.6 + (y - 5) * .52, max(.16, 1 - ((f / 2 - k * 1.25) % 10) / 7)) for k, (x, y) in enumerate([(5 + 4.4 * math.cos(2 * math.pi * k / 8 - math.pi / 2), 5 + 4.4 * math.sin(2 * math.pi * k / 8 - math.pi / 2)) for k in range(8)])]
    return [(x, y, 1) for y, r in enumerate(S[name][0]) for x, c in enumerate(r) if c == "#"]
HOT = {"wait": (5, 5), "progress": (0, 0)}
def render(name, size, f=0):
    cell = size / 15; D = dots(name, f); M = 1.15
    w = math.ceil((max(d[0] for d in D) + 1 + 2 * M) * cell); h = math.ceil((max(d[1] for d in D) + 1 + 2 * M) * cell)
    small = cell * (.62 if name == "progress" else 1)
    B, W = [0.0] * (w * h), [0.0] * (w * h)
    for x, y, v in D:
        tiny = name == "progress" and v != 1 or name == "progress" and x > 7.2 and y > 6.9
        s = cell * (.6 if tiny else 1); cx, cy = (x + .5 + M) * cell, (y + .5 + M) * cell; Rb, Rw = 1.02 * s + .25, .41 * s + .1
        if tiny: Rb += .25 * cell
        for py in range(max(0, int(cy - Rb - 1)), min(h, int(cy + Rb + 2))):
            for px in range(max(0, int(cx - Rb - 1)), min(w, int(cx + Rb + 2))):
                d = math.hypot(px + .5 - cx, py + .5 - cy); i = py * w + px
                b = min(1, max(0, Rb - d + .5)); wv = min(1, max(0, Rw - d + .5)) * v
                if b > B[i]: B[i] = b
                if wv > W[i]: W[i] = wv
    px = bytearray()
    for b, v in zip(B, W):
        a = round(b * 255); c = min(a, round(v * 255)); px += struct.pack("<I", a << 24 | c << 16 | c << 8 | c)
    hx, hy = HOT.get(name) or S[name][1:]
    edge = 0.25 if name not in ("wait",) and (hx, hy) == (0, 0) else 0.5      # arrows point with their tip
    return w, h, min(w - 1, int((hx + edge + M) * cell)), min(h - 1, int((hy + edge + M) * cell)), bytes(px)
def write(path, name):
    n = FR if name in ("wait", "progress") else 1
    im = [(s, *render(name, s, f)) for s in SIZES for f in range(n)]
    head = struct.pack("<4sIII", b"Xcur", 16, 0x10000, len(im)); pos = 16 + 12 * len(im); toc = body = b""
    for s, w, h, x, y, px in im:
        toc += struct.pack("<III", 0xfffd0002, s, pos)
        c = struct.pack("<IIIIIIIII", 36, 0xfffd0002, s, 1, w, h, x, y, 40 if n > 1 else 0) + px; body += c; pos += len(c)
    with open(path, "wb") as f: f.write(head + toc + body)
LINKS = """default: arrow left_ptr top_left_arrow wayland-cursor center_ptr
right_ptr: draft_large draft_small
help: question_arrow whats_this left_ptr_help d9ce0ab605698f320427677b458ad60b 5c6cd98b3f3ebcb1f9c7f1c204630408 dnd-ask
pointer: hand1 hand2 pointing_hand 9d800788f1b08800ae810202380a0822 e29285e634086352946a0e7090d73106
openhand: grab hand
dnd-move: closedhand grabbing dnd-none move 4498f0e0c1937ffe01fd06f973665830 9081237383d90e509aa00f00170e968f fcf21c00b30f7e3f83fe0dfd12e71cff
copy: dnd-copy 1081e37283d90000800003c07f3ef6bf 6407b0e94181790501fd1e167b474872 b66166c04f8c3109214a4fbd64a50fc8
alias: link dnd-link 3085a0e285430894940527032f8b26df 640fb0e74195791501fd1ed57b41487f a2a266d0498c3104214a47bd64ab0fc8
no-drop: forbidden dnd-no-drop 03b6e0fcb3499374a867d041f52298f0
not-allowed: circle crossed_circle 03b6e0fcb3499374a867c041f52298f0
text: xterm ibeam
crosshair: cross tcross diamond_cross cross_reverse
cell: plus
size_hor: ew-resize e-resize w-resize h_double_arrow sb_h_double_arrow left_side right_side 028006030e0e7ebffc7f7070c0600140
size_ver: ns-resize n-resize s-resize v_double_arrow sb_v_double_arrow top_side bottom_side 00008160000006810000408080010102
size_fdiag: nwse-resize nw-resize se-resize top_left_corner bottom_right_corner ul_angle lr_angle c7088f0f3e6c8088236ef8e1e3e70000
size_bdiag: nesw-resize ne-resize sw-resize top_right_corner bottom_left_corner ur_angle ll_angle fcf1c3c7cd4491d801f1e1c78f100000
col-resize: split_h 14fef782d02440884392942c11205230 043a9f68147c53184671403ffa811cc5
row-resize: split_v 2870a09082c103050810ffdffffe0204 c07385c7190e701020ff7ffffd08103c
fleur: size_all all-scroll
up-arrow: sb_up_arrow
down-arrow: sb_down_arrow
left-arrow: sb_left_arrow
right-arrow: sb_right_arrow
wait: watch 0426c94ea35c87780ff01dc239897213
progress: left_ptr_watch half-busy 00000000000000020006000e7e9ffc3f 08e8e1c95fe2fc01f976f1e063a24ccd 3ecb610c1bf2410f44200f48c40d3599
pencil: draft
x-cursor: X_cursor pirate kill
zoom-in: zoom
context-menu: tty_dummy"""
C = OUT + "/cursors"; shutil.rmtree(OUT, ignore_errors=True); os.makedirs(C)
for n in list(S) + ["wait", "progress"]: write(f"{C}/{n}", n)
for l in LINKS.split("\n"):
    n, _, al = l.partition(": ")
    for a in al.split():
        if a != "tty_dummy" and not os.path.lexists(f"{C}/{a}"): os.symlink(n, f"{C}/{a}")
open(OUT + "/index.theme", "w").write("[Icon Theme]\nName=Framework Dots\nComment=Dot-matrix pointers in black and white\nInherits=breeze_cursors\n")
print(len(os.listdir(C)), "names")
