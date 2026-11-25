uniform sampler2D sampler;
uniform int textureWidth;
uniform int textureHeight;
uniform float pour;         // 0: the whole window, 1: gone
uniform vec4 accent;
varying vec2 texcoord0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void main()
{
    vec2 size = vec2(float(textureWidth), float(textureHeight));
    float pitch = 26.0;                                                     // large, because the window shrinks on the way
    vec2 px = texcoord0 * size;
    vec2 cell = floor(px / pitch);
    float order = 0.45 * hash(cell) + 0.55 * cell.y * pitch / max(size.y, 1.0);
    float broken = clamp(pour * 4.2 - order, 0.0, 1.0);                     // the window breaks into dots first
    float fade = smoothstep(0.84, 1.0, pour);                               // and they disappear as they arrive
    float radius = mix(0.74, 0.36, broken) * (1.0 - 0.75 * fade);
    float dist = length(fract(px / pitch) - 0.5);
    float mask = broken <= 0.0 ? 1.0 : 1.0 - smoothstep(radius - 0.06, radius + 0.03, dist);
    vec4 c = texture2D(sampler, texcoord0);
    c.rgb = mix(c.rgb, accent.rgb * c.a, 0.85 * smoothstep(0.35, 1.0, broken) * step(0.85, c.a));
    gl_FragColor = c * mask * (1.0 - fade);
}
