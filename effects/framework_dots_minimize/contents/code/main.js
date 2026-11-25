"use strict";
// Dot Minimize: windows break into dots and pour into their task bar icon.
// The movement follows KWin's Squash effect, SPDX-FileCopyrightText: 2018 Vlad Zahorodnii, GPL-2.0-or-later
const ACCENT = "#f3531a";

class DotMinimize {
    constructor() {
        this.shader = 0;
        try {
            this.shader = effect.addFragmentShader(Effect.MapTexture, "pour.frag");
            if (this.shader) effect.setUniform(this.shader, "accent", ACCENT);
        } catch (e) { this.shader = 0; }
        effect.configChanged.connect(this.load.bind(this));
        effect.animationEnded.connect(w => w.setData(Effect.WindowForceBlurRole, null));
        effects.windowAdded.connect(this.watch.bind(this));
        for (const w of effects.stackingOrder) this.watch(w);
        this.load();
    }
    load() { this.time = animationTime(460); }
    watch(w) { w.minimizedChanged.connect(() => this.go(w, w.minimized)); }
    go(w, down) {
        if (effects.hasActiveFullScreenEffect) return;
        const icon = w.iconGeometry;
        if (icon.width == 0 || icon.height == 0) return;        // not in the task bar
        const other = down ? "dotsUp" : "dotsDown", mine = down ? "dotsDown" : "dotsUp";
        if (w[other]) {
            if (redirect(w[other], Effect.Backward)) return;    // turn around where it is
            cancel(w[other]); delete w[other];
        }
        if (w[mine]) {
            if (redirect(w[mine], Effect.Forward)) return;
            cancel(w[mine]);
        }
        const g = w.geometry, size = { value1: g.width, value2: g.height }, small = { value1: icon.width, value2: icon.height };
        const home = { value1: 0, value2: 0 }, there = { value1: icon.x - g.x - (g.width - icon.width) / 2, value2: icon.y - g.y - (g.height - icon.height) / 2 };
        const a = [
            { type: Effect.Size, from: down ? size : small, to: down ? small : size },
            { type: Effect.Translation, from: down ? home : there, to: down ? there : home },
            this.shader
                ? { type: Effect.ShaderUniform, fragmentShader: this.shader, uniform: "pour", from: down ? 0 : 1, to: down ? 1 : 0, curve: QEasingCurve.Linear }
                : { type: Effect.Opacity, from: down ? 1 : 0, to: down ? 0 : 1 }
        ];
        w.setData(Effect.WindowForceBlurRole, true);
        w[mine] = animate({ window: w, curve: QEasingCurve.InOutSine, duration: this.time, keepAlive: false, animations: a });
    }
}
new DotMinimize();
