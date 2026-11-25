"use strict";
// Dot Dissolve: windows form from dots when they open and dissolve into dots when they close.
const ACCENT = "#f3531a";
const skip = { "ksmserver ksmserver": [], "ksmserver-logout-greeter ksmserver-logout-greeter": [], "ksplashqml ksplashqml": [], "spectacle org.kde.spectacle": ["region-editor"] };

class Dissolve {
    constructor() {
        this.shader = 0;
        try {
            this.shader = effect.addFragmentShader(Effect.MapTexture, "dissolve.frag");
            if (this.shader) effect.setUniform(this.shader, "accent", ACCENT);
        } catch (e) { this.shader = 0; }
        effect.configChanged.connect(this.load.bind(this));
        effect.animationEnded.connect(this.release.bind(this));
        effects.windowAdded.connect(this.added.bind(this));
        effects.windowClosed.connect(this.closed.bind(this));
        effects.windowDataChanged.connect(this.grabbed.bind(this));
        this.load();
    }
    load() { this.inTime = animationTime(330); this.outTime = animationTime(380); }
    // The same windows KWin's own Scale effect animates
    static wanted(w) {
        if (w.windowClass == "plasmashell plasmashell" || w.windowClass == "plasmashell org.kde.plasmashell") return w.hasDecoration;
        const tags = skip[w.windowClass];
        if (tags && (tags.length === 0 || tags.includes(w.tag))) return false;
        if (w.hasDecoration) return true;
        if (w.popupWindow || w.lockScreen || w.outline || !w.managed) return false;
        return w.normalWindow || w.dialog;
    }
    release(w) { w.setData(Effect.WindowForceBackgroundContrastRole, null); w.setData(Effect.WindowForceBlurRole, null); }
    run(w, opening) {
        const a = this.shader
            ? [{ type: Effect.ShaderUniform, fragmentShader: this.shader, uniform: "dissolve", from: opening ? 1 : 0, to: opening ? 0 : 1 }]
            : [{ type: Effect.Opacity, from: opening ? 0 : 1, to: opening ? 1 : 0 }];
        return animate({ window: w, curve: opening ? QEasingCurve.OutQuad : QEasingCurve.InOutSine, duration: opening ? this.inTime : this.outTime, animations: a });
    }
    added(w) {
        if (effects.hasActiveFullScreenEffect || !Dissolve.wanted(w) || !w.visible || effect.isGrabbed(w, Effect.WindowAddedGrabRole)) return;
        w.dotsIn = this.run(w, true);
    }
    closed(w) {
        if (effects.hasActiveFullScreenEffect || !Dissolve.wanted(w) || !w.visible || w.skipsCloseAnimation || effect.isGrabbed(w, Effect.WindowClosedGrabRole)) return;
        if (w.dotsIn) { cancel(w.dotsIn); delete w.dotsIn; }
        w.dotsOut = this.run(w, false);
    }
    grabbed(w, role) {
        if (role == Effect.WindowAddedGrabRole && w.dotsIn && effect.isGrabbed(w, role)) { cancel(w.dotsIn); delete w.dotsIn; }
        else if (role == Effect.WindowClosedGrabRole && w.dotsOut && effect.isGrabbed(w, role)) { cancel(w.dotsOut); delete w.dotsOut; }
    }
}
new Dissolve();
