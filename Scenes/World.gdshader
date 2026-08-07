shader_type canvas_item;

// Hint required for screen texture sampling in Godot 4+
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float saturation : hint_range(0.0, 3.0) = 1.12;
uniform float contrast : hint_range(0.0, 3.0) = 1.18;
uniform float brightness : hint_range(-1.0, 1.0) = -0.04;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.25;
uniform vec3 warm = vec3(1.05, 1.00, 0.94);

void fragment() {
    // Corrected screen texture lookup
    vec4 c = texture(screen_texture, SCREEN_UV);

    // Warm tinting
    c.rgb *= warm;

    // Saturation adjustment
    float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    c.rgb = mix(vec3(gray), c.rgb, saturation);

    // Contrast adjustment
    c.rgb = (c.rgb - 0.5) * contrast + 0.5;

    // Brightness adjustment
    c.rgb += brightness;

    // Vignette
    vec2 uv = SCREEN_UV * 2.0 - 1.0;
    float vig = 1.0 - dot(uv, uv) * vignette_strength;
    c.rgb *= clamp(vig, 0.0, 1.0);

    COLOR = c;
}