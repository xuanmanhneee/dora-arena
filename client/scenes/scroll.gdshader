shader_type canvas_item;

uniform float speed : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    vec2 uv = fract(UV + vec2(TIME * speed, 0.0));
    COLOR = texture(TEXTURE, uv);
}