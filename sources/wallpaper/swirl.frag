#version 440
// The swirl's dots, one pixel per dot. Recreates the old web wallpaper's swirl: particles are born near the middle and
// drift outwards on a tilted spiral, turning faster near the centre. Positions follow from the time alone; the previous
// frame is fed back in and faded for the trails.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 grid;      // dots across and down
    float time;     // seconds, already multiplied by the speed
    float keep;     // how much of the last frame is left
    float inject;   // how strongly new particles light up
    float holeSize; // empty middle, as in the original's "hole" setting
    float spread;
    float flat_;
    float tilt;
    vec2 centre;
};
layout(binding = 1) uniform sampler2D prev;

const float V = 0.00975;        // outward speed, in screen widths a second
const float ROW = 0.0256;       // seconds between particle rows
const float PER = 7.0;          // particles in each row (about 4500 on screen, denser than the original)
const float ROWS = 25600.0;     // rows before the pattern repeats (655.36 s)
const float TAU = 6.2831853;

uint pcg(uint v) { uint st = v * 747796405u + 2891336453u; uint w = ((st >> ((st >> 28u) + 4u)) ^ st) * 277803737u; return (w >> 22u) ^ w; }
float hashi(float a, float b) { return float(pcg(pcg(uint(a)) ^ uint(b) * 2654435761u)) / 4294967295.0; }
// how far a particle has turned by the time it is at radius r (it turns faster near the middle)
float turned(float r) { return 0.42 * 0.925 * pow(0.2, 0.75) * 4.0 * (pow(r + 0.06, 0.25) - pow(0.06, 0.25)) / V; }

void main() {
    vec2 cell = floor(qt_TexCoord0 * grid);
    float c = cos(tilt), s = sin(tilt), q = 1.0 - flat_, Wd = grid.x;
    vec2 ctr = centre * grid, d = cell - ctr;
    vec2 u = vec2(d.x * c + d.y * s, -d.x * s + d.y * c);
    vec2 P = vec2(u.x, u.y / q) / Wd;
    float rc = length(P), thc = atan(P.y, P.x), e = 0.0;
    float dr = 3.4 / Wd / q;                               // a dot and a half, plus the wobble
    float j0 = floor((time - (rc + dr) / V) / ROW), j1 = min(floor((time - max(rc - dr, 0.0) / V) / ROW), j0 + 120.0);
    for (float j = j0; j <= j1; j += 1.0) {
        float jm = mod(j, ROWS); if (jm < 0.0) jm += ROWS;
        float tj = (j + hashi(jm, 17.0)) * ROW;
        float r = (time - tj) * V;
        if (r <= 0.0) continue;
        float tr = turned(r), m0 = floor((thc - tr) / TAU * PER);
        for (float k = -1.0; k <= 1.0; k += 1.0) {
            float m = m0 + k, mm = mod(m, PER), id = jm * PER + mm;
            float h1 = hashi(id, 1.0), h2 = hashi(id, 2.0), h3 = hashi(id, 3.0), h4 = hashi(id, 4.0), h5 = hashi(id, 5.0), h6 = hashi(id, 6.0);
            // where it is born and how far it gets, as in the original (r0 and dr)
            float g3 = -log(1.0 - h1 * 0.999) - log(1.0 - h5 * 0.999) - log(1.0 - h6 * 0.999);
            float rs = (holeSize * 0.24 + 0.02 + g3 * 0.045) * spread, re = rs + (0.045 + h4 * 0.15) * spread;
            if (r < rs || r > re) continue;
            float uu = (r - rs) / (re - rs);
            float th = (m + h2) / PER * TAU + tr;
            vec2 w = vec2(r * cos(th), r * sin(th) * q) * Wd;
            w.y += 1.5 * sin(h3 * TAU + TAU * uu);
            vec2 p = ctr + vec2(w.x * c - w.y * s, w.x * s + w.y * c);
            vec2 t = max(vec2(0.0), 1.0 - abs(p - cell) / 1.45) / 1.45;
            float a = (0.35 + 0.65 * pow(hashi(id, 7.0), 1.6)) * pow(sin(3.14159 * uu), 0.7);
            e += a * t.x * t.y;
        }
    }
    float v = texture(prev, qt_TexCoord0).r * keep + e * inject;
    fragColor = vec4(v, v, v, 1.0);
}
