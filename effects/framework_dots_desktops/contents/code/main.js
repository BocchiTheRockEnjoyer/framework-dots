"use strict";
// Dot Wipe: switching virtual desktops sweeps the old windows away as dots and forms the new ones behind.
// Which windows take part follows KWin's Fade Desktop effect, SPDX-FileCopyrightText: 2018 Vlad Zahorodnii, GPL-2.0-or-later
const ACCENT = "#f3531a";

class DotWipe {
    constructor() {
        this.shader = 0;
        try {
            this.shader = effect.addFragmentShader(Effect.MapTexture, "wipe.frag");
            if (this.shader) effect.setUniform(this.shader, "accent", ACCENT);
        } catch (e) { this.shader = 0; }
        effect.configChanged.connect(this.load.bind(this));
        effect.isActiveFullScreenEffectChanged.connect(this.blur.bind(this));
        effects.desktopChanged.connect(this.changed.bind(this));
        this.load();
    }
    load() { this.time = animationTime(420); }
    blur() {
        const on = effect.isActiveFullScreenEffect;
        for (const w of effects.stackingOrder) { w.setData(Effect.WindowForceBlurRole, on); w.setData(Effect.WindowForceBackgroundContrastRole, on); }
    }
    // Which way the desktops are laid out: [1, 0] is to the right, [0, 1] is down
    static way(from, to) {
        const cols = Math.max(1, effects.desktopGridWidth || 1), a = (from ? from.x11DesktopNumber : 1) - 1, b = (to ? to.x11DesktopNumber : 1) - 1;
        const dx = b % cols - a % cols, dy = Math.floor(b / cols) - Math.floor(a / cols);
        return Math.abs(dy) > Math.abs(dx) ? [0, dy < 0 ? -1 : 1] : [dx < 0 ? -1 : 1, 0];
    }
    // Where the window is along the sweep: start, then the change across its width and height
    static place(w, way) {
        const s = w.screen && w.screen.geometry && w.screen.geometry.width ? w.screen.geometry : effects.virtualScreenGeometry, g = w.geometry;
        if (way[0]) { const x = (g.x - s.x) / s.width, d = g.width / s.width; return way[0] > 0 ? [1 - x, -d, 0] : [x, d, 0]; }
        const y = (g.y - s.y) / s.height, d = g.height / s.height;
        return way[1] > 0 ? [1 - y, 0, -d] : [y, 0, d];
    }
    run(w, arriving, way) {
        const other = arriving ? "wipeOut" : "wipeIn", mine = arriving ? "wipeIn" : "wipeOut";
        if (w[other]) {
            if (redirect(w[other], Effect.Backward)) return;    // switched back halfway: turn around
            cancel(w[other]); delete w[other];
        }
        if (w[mine]) {
            if (redirect(w[mine], Effect.Forward)) return;
            cancel(w[mine]); delete w[mine];
        }
        let a;
        if (this.shader) {
            const p = DotWipe.place(w, way), fixed = (uniform, v) => ({ type: Effect.ShaderUniform, fragmentShader: this.shader, uniform: uniform, from: v, to: v });
            a = [{ type: Effect.ShaderUniform, fragmentShader: this.shader, uniform: "wipe", from: 0, to: 1 },
                 fixed("arriving", arriving ? 1 : 0), fixed("start", p[0]), fixed("across", p[1]), fixed("down", p[2])];
        } else a = [{ type: Effect.Opacity, from: arriving ? 0 : 1, to: arriving ? 1 : 0 }];
        w[mine] = animate({ window: w, curve: QEasingCurve.InOutSine, duration: this.time, fullScreen: true, keepAlive: false, animations: a });
    }
    changed(from, to, moving, screen) {
        if (effects.hasActiveFullScreenEffect && !effect.isActiveFullScreenEffect) return;
        const way = DotWipe.way(from, to);
        for (const w of effects.stackingOrder) {
            if (w == moving || (screen && w.screen !== screen) || w.minimized || !w.isOnActivity(effects.currentActivity)) continue;
            const before = w.isOnDesktop(from), after = w.isOnDesktop(to);
            if (before != after) this.run(w, after, way);
        }
    }
}
new DotWipe();
