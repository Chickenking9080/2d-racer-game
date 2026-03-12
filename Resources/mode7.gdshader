shader_type canvas_item;

// This uses the whole screen texture instead of individual tiles
uniform sampler2D screen_tex : hint_screen_texture, repeat_enable, filter_nearest;

void fragment() {
    float horizon = 0.5; // Adjust this to tilt the map
    float v = (SCREEN_UV.y - horizon) / (1.0 - horizon);
    
    if (SCREEN_UV.y > horizon) {
        vec2 uv = vec2((SCREEN_UV.x - 0.5) / v + 0.5, 1.0 / v);
        // This grabs the "rendered" tiles from the screen
        COLOR = texture(screen_tex, uv);
    } else {
        // Sky color
        COLOR = vec4(0.4, 0.6, 0.9, 1.0);
    }
}
