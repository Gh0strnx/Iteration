shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;
uniform bool outline_enabled = true;
uniform vec4 player_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 size = outline_width * TEXTURE_PIXEL_SIZE;
    float alpha = texture(TEXTURE, UV).a;
    float outline = 0.0;
    if (outline_enabled) {
        outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
        outline += texture(TEXTURE, UV - vec2(size.x, 0.0)).a;
        outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
        outline += texture(TEXTURE, UV - vec2(0.0, size.y)).a;
        outline += texture(TEXTURE, UV + size).a;
        outline += texture(TEXTURE, UV - size).a;
        outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
        outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
        outline = min(outline, 1.0);
    }
    vec4 base = texture(TEXTURE, UV) * player_color;
    COLOR = mix(base, outline_color, outline * (1.0 - alpha));
}