#version 440
// Draws each dot from its brightness. The same look as the old web wallpaper.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 grid;
    vec2 res;       // pixels
    float pitch;
    float size;
    float unlit;
    float square;
    float gain;
    float fade;     // darker towards the right, as in the original
    vec4 col;
    vec4 hot;
    vec4 bg;
};
layout(binding = 1) uniform sampler2D field;
void main() {
    vec2 px = qt_TexCoord0 * res;
    vec2 c = floor(px / pitch);
    float fc = clamp(1.0 + 0.15 * min(1.0, fade / 50.0) - (c.x / grid.x) * 1.05 * fade / 100.0, 0.1, 1.0);
    float e = texture(field, (c + 0.5) / grid).r * gain * fc;
    float v = 1.0 - exp(-e);
    vec2 q = abs(fract(px / pitch) - 0.5) * 2.0;
    float dd = mix(length(q), max(q.x, q.y), square);
    float r = mix(0.18 + 0.12 * unlit, size, pow(v, 0.75));
    float a = smoothstep(-0.9, 0.9, (r - dd) * pitch * 0.5);        // softly edged dots
    float lt = smoothstep(0.25, 0.75, dot(bg.rgb, vec3(0.333)));
    vec3 off = bg.rgb + vec3(mix(0.11, -0.14, lt)) * unlit;
    vec3 low = mix(col.rgb * 0.38, mix(bg.rgb, col.rgb, 0.5), lt);
    vec3 k = v < 0.22 ? mix(off, low, v / 0.22) : v < 0.68 ? mix(low, col.rgb, (v - 0.22) / 0.46) : mix(col.rgb, hot.rgb, (v - 0.68) / 0.32);
    float vis = max(step(0.004, v), step(0.001, unlit));
    fragColor = vec4(mix(bg.rgb, k, a * vis), 1.0) * qt_Opacity;
}
