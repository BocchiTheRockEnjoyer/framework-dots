#version 140
uniform sampler2D sampler;
uniform int textureWidth;
uniform int textureHeight;
uniform float dissolve;     // 0: the whole window, 1: gone
uniform vec4 accent;
in vec2 texcoord0;
out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void main()
{
    vec2 size = vec2(float(textureWidth), float(textureHeight));
    float pitch = 14.0;
    vec2 px = texcoord0 * size;
    vec2 cell = floor(px / pitch);
    float order = 0.55 * hash(cell) + 0.45 * (1.0 - cell.y * pitch / max(size.y, 1.0));   // each dot leaves at its own time, roughly along the window
    float gone = clamp(dissolve * 1.7 - order * 0.7, 0.0, 1.0);
    float radius = 0.74 * (1.0 - gone);                                                    // 0.71 covers the corners of a cell
    float dist = length(fract(px / pitch) - 0.5);
    float mask = gone <= 0.0 ? 1.0 : 1.0 - smoothstep(radius - 0.07, radius + 0.02, dist);
    vec4 c = texture(sampler, texcoord0);
    float tint = smoothstep(0.25, 0.8, gone) * step(0.85, c.a);                            // the window itself, not its shadow
    c.rgb = mix(c.rgb, accent.rgb * c.a, tint);
    float left = gone >= 1.0 ? 0.0 : mask;
    fragColor = c * left;
}
