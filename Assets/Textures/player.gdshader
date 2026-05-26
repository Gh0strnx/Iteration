shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;
uniform bool outline_enabled = true;
uniform vec4 player_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 frame_size = vec2(64.0, 32.0);
uniform vec2 sheet_size = vec2(1088.0, 64.0);

void fragment() {
    vec2 pixel_size = 1.0 / sheet_size;
    vec2 size = outline_width * pixel_size;

    // Calculate the current frame's UV bounds
    vec2 frame_uv_size = frame_size / sheet_size;
    vec2 frame_origin = floor(UV / frame_uv_size) * frame_uv_size;
    vec2 frame_min = frame_origin;
    vec2 frame_max = frame_origin + frame_uv_size;

    vec4 base = texture(TEXTURE, UV) * player_color;
    float alpha = base.a;

    float outline = 0.0;
    if (outline_enabled) {
        vec2 offsets[8];
        offsets[0] = vec2( size.x,     0.0);
        offsets[1] = vec2(-size.x,     0.0);
        offsets[2] = vec2(    0.0,  size.y);
        offsets[3] = vec2(    0.0, -size.y);
        offsets[4] = vec2( size.x,  size.y);
        offsets[5] = vec2(-size.x, -size.y);
        offsets[6] = vec2( size.x, -size.y);
        offsets[7] = vec2(-size.x,  size.y);

        for (int i = 0; i < 8; i++) {
            vec2 sample_uv = clamp(UV + offsets[i], frame_min, frame_max);
            outline += texture(TEXTURE, sample_uv).a;
        }
        outline = min(outline, 1.0);
    }

    COLOR = mix(base, outline_color, outline * (1.0 - alpha));
}