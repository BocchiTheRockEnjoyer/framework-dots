#version 140
uniform sampler2D sampler;
uniform int textureWidth;
uniform int textureHeight;
uniform float wipe;         // how far the sweep has got
uniform float arriving;     // 1: forming, 0: leaving
uniform float start;        // place along the sweep, and the change across the window
uniform float across;
uniform float down;
uniform vec4 accent;
in vec2 texcoord0;
out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void main()
{
    vec2 size = vec2(float(textureWidth), float(textureHeight));
    float pitch = 16.0;
    vec2 px = texcoord0 * size;
    vec2 cell = floor(px / pitch);
    vec2 at = (cell + 0.5) * pitch / max(size, vec2(1.0));
    float s = start + across * at.x + down * at.y + 0.10 * (hash(cell) - 0.5);
    float edge = 0.38;                                                      // how wide the band of dots is
    float gone = clamp((wipe * (1.1 + 2.0 * edge) - 0.05 - s - edge * arriving) / edge, 0.0, 1.0);    // new windows follow behind
    gone = mix(gone, 1.0 - gone, arriving);
    float radius = 0.74 * (1.0 - gone);                                     // 0.71 covers the corners of a cell
    float dist = length(fract(px / pitch) - 0.5);
    float mask = gone <= 0.0 ? 1.0 : 1.0 - smoothstep(radius - 0.07, radius + 0.02, dist);
    vec4 c = texture(sampler, texcoord0);
    c.rgb = mix(c.rgb, accent.rgb * c.a, smoothstep(0.3, 0.85, gone) * step(0.85, c.a));
    float left = gone >= 1.0 ? 0.0 : mask;
    fragColor = c * left;
}
