#version 440
// The black hole's dots, one pixel per dot. Recreates the old web wallpaper's particles: each one starts somewhere in the
// disc, spirals inwards faster and faster, and piles up at the edge of the hole. Where a particle is depends only on the
// time, so nothing has to be stored: every dot looks up the few particles that can be near it.
// The previous frame is fed back in and faded, which gives the same short glowing trails.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 grid;      // dots across and down
    float time;     // seconds, already multiplied by the speed
    float keep;     // how much of the last frame is left
    float inject;   // how strongly new particles light up
    float holeSize; // hole radius as a share of the width
    float bend;
    float ring;
    float stars;
    float spread;
    float flat_;
    float tilt;
    vec2 centre;
};
layout(binding = 1) uniform sampler2D prev;

const float EDGE = 1.22;        // particles end here, in hole radii
const float K = 0.211;          // inward speed: dr/dt = -K (r - EDGE)^0.2
const float ROW = 0.01;         // seconds between particle rows
const float PER = 7.0;          // particles in each row (700 a second, about 14000 in the disc)
const float TAU = 6.2831853;

uint pcg(uint v) { uint st = v * 747796405u + 2891336453u; uint w = ((st >> ((st >> 28u) + 4u)) ^ st) * 277803737u; return (w >> 22u) ^ w; }
float hash(vec2 p) { return float(pcg(uint(int(p.x)) * 1597334677u ^ pcg(uint(int(p.y)) + 3812015801u))) / 4294967295.0; }
float hashi(float a, float b) { return float(pcg(pcg(uint(a)) ^ uint(b) * 2654435761u)) / 4294967295.0; }

// time left before a particle at radius r reaches the edge, and back
float sigma(float r) { return pow(max(r - EDGE, 0.0), 0.8) / (0.8 * K); }
float radiusAt(float s) { return EDGE + pow(max(s, 0.0) * 0.8 * K, 1.25); }
float spin(float r) { return 1.9 * pow(max(r, 0.5), -1.35) * 0.92; }
// how far a particle at radius r still turns before it reaches the edge
float turns(float r) {
    float s1 = pow(max(r - EDGE, 0.0), 0.8), h = s1 / 6.0, a = 0.0;
    for (int i = 0; i <= 6; i++) { float w = (i == 0 || i == 6) ? 1.0 : (i % 2 == 1 ? 4.0 : 2.0); a += w * spin(EDGE + pow(float(i) * h, 1.25)); }
    return a * h / 3.0 / (0.8 * K);
}

void main() {
    vec2 cell = floor(qt_TexCoord0 * grid);
    float Rh = max(2.0, holeSize * grid.x), c = cos(tilt), s = sin(tilt), q = 1.0 - flat_, b2 = 1.15 * bend;
    vec2 ctr = centre * grid;

    // where this dot is in the disc (radius and angle), undoing the tilt, the flattening and the bending of light
    vec2 d = cell - ctr;
    vec2 u = vec2(d.x * c + d.y * s, -d.x * s + d.y * c) / Rh;
    float L = length(u) + 1e-4, rc, thc;
    if (u.y >= 0.0) { vec2 P = vec2(u.x, u.y / q); rc = length(P); thc = atan(P.y, P.x); }
    else {
        float back = 1.0;
        for (int i = 0; i < 3; i++) { float R = max(L - b2 * back / L, 1e-3); back = clamp(-(u.y * R / L) / q * 1.2 + 0.15, 0.0, 1.0); }
        float R = max(L - b2 * back / L, 1e-3); vec2 w = u * (R / L); vec2 P = vec2(w.x, w.y / q); rc = length(P); thc = atan(P.y, P.x);
    }

    float e = 0.0;
    if (rc > EDGE - 0.05 && rc < 12.0) {
        // rows of particles that are within about a dot and a half of this radius now
        float dr = 1.6 / Rh, sLo = sigma(rc - dr), sHi = sigma(rc + dr);
        float j0 = floor((time + sLo) / ROW), j1 = min(floor((time + sHi) / ROW), j0 + 90.0);
        for (float j = j0; j <= j1; j += 1.0) {
            float jm = mod(j, 65536.0);
            float tj = (j + hashi(jm, 17.0)) * ROW;
            float left = tj - time;                     // time until this row reaches the edge
            if (left < 0.0) continue;
            float r = radiusAt(left);
            // the angle a particle needs to be at this dot now, then the nearest particles in the row
            float tr = turns(r), want = thc + tr;
            float m0 = floor(want / TAU * PER);
            for (float k = -1.0; k <= 1.0; k += 1.0) {
                float m = m0 + k, mm = mod(m, PER);
                float id = jm * PER + mm; float h1 = hashi(id, 1.0), h2 = hashi(id, 2.0), h3 = hashi(id, 3.0), h4 = hashi(id, 4.0);
                float out_ = (2.2 + 6.5 * pow(h1, 1.4)) * spread;
                if (r > EDGE + out_) continue;           // not born yet
                float uu = 1.0 - pow((r - EDGE) / out_, 0.8);
                float th = (m + h2) / PER * TAU - tr;
                float X = r * cos(th), Z = r * sin(th);
                float x = X, y = Z * q + (h4 - 0.5) * 0.12;
                float R = sqrt(x * x + y * y) + 1e-4, back = clamp(-Z * 1.2 + 0.15, 0.0, 1.0);
                float Lp = (R + sqrt(R * R + 4.0 * b2 * back)) / 2.0;
                if (Z < 0.0 && Lp < 1.02) continue;       // hidden behind the hole
                x *= Lp / R; y *= Lp / R;
                vec2 p = ctr + vec2(x * c - y * s, x * s + y * c) * Rh;
                vec2 t = max(vec2(0.0), 1.0 - abs(p - cell) / 1.45) / 1.45;     // a little wider than one dot, so particles glide instead of hopping
                float a = (0.35 + 0.65 * pow(h3, 1.6)) * min(1.0, uu * 6.0) * pow(3.2 / (r + 1.2), 1.25);
                e += a * t.x * t.y;
            }
        }
    }
    float v = texture(prev, qt_TexCoord0).r * keep + e * inject;

    // the bright ring hugging the hole, and a few faint stars, as in the original
    float dd = length(cell + 0.5 - ctr) / Rh, wd = max(0.085, 0.62 / Rh);
    float glow = exp(-pow((dd - 1.14) / wd, 2.0)) * 0.95 + (dd > 1.1 ? exp(-max(0.0, dd - 1.14) * 4.2) * 0.16 : 0.0);
    if (glow > 0.02) v = max(v, glow * ring);
    float hs = hash(cell + 3.0);
    if (dd > 1.3 && hs > 1.0 - 0.012 * stars) v = max(v, (0.05 + 0.16 * fract(hs * 91.0)) * (0.75 + 0.25 * sin(time * 1.3 + hs * 40.0)));
    fragColor = vec4(v, v, v, 1.0);
}
