#language slang 2026

import kitty_custom_shader_types;

// Independent implementation inspired by patricorgi/kitty-sliding-tabs.
// Python passes actual cell geometry and animated pixel bounds through blank
// tab cells; all metadata is removed by this final pass.
static const float LEFT_INSET = 12.0;
static const bool MOVING = false;
static const int OFFSETS[7] = {0, 16, 32, 48, 64, 80, 96};

float3 linear_rgb(float3 rgb) {
    float3 v = rgb / 255.0;
    return float3(v.x <= 0.04045 ? v.x / 12.92 : pow((v.x + 0.055) / 1.055, 2.4),
                  v.y <= 0.04045 ? v.y / 12.92 : pow((v.y + 0.055) / 1.055, 2.4),
                  v.z <= 0.04045 ? v.z / 12.92 : pow((v.z + 0.055) / 1.055, 2.4));
}

int decode(KittyTextures t, float2 at, int signature) {
    float3 rgb = t.backbuffer.Sample(at).rgb;
    if (any(rgb < 0.10)) return -1;
    float3 srgb = 1.055 * pow(rgb, float3(1.0 / 2.4)) - 0.055;
    int3 n = int3(round((srgb * 255.0 - 96.0) / 5.0));
    if (any(n < 0) || any(n > 31)) return -1;
    int value = (n.x << 10) | (n.y << 5) | n.z;
    return value >> 13 == signature ? value & 8191 : -1;
}

float ink_coverage(float3 color, float3 background, float3 ink) {
    float3 delta = ink - background;
    return saturate(dot(color - background, delta) / max(dot(delta, delta), 0.00001));
}

public float4 fragment_main(float4 color, KittyTextures t, uniform KittyCustomShaderData d) {
    float2 pixel = 1.0 / float2(d.viewport_size_pixels);
    float bottom = d.central_area.y + d.central_area.w;
    if (t.pos.y < bottom) return color;
    // Sample the empty first cell away from the texture boundary.
    float sample_y = bottom + 2.5 * pixel.y;
    int grid = decode(t, float2((LEFT_INSET + 2.5) * pixel.x, sample_y), 0);
    if (grid < 0) return color;
    float cw = float(grid >> 7);
    float ch = float(grid & 127);
    if (cw < 1.0 || ch < 4.0) return color;
    float top = bottom + ch * pixel.y;
    if (t.pos.y >= top) return color;
    int columns = int(floor((float(d.viewport_size_pixels.x) - 2.0 * LEFT_INSET) / cw));
    float x = t.pos.x / pixel.x;
    float4 background = t.backbuffer.Sample(float2(0.5 * pixel.x, sample_y));
    float3 bg = background.rgb / max(background.a, 0.00001);
    float3 highlight = linear_rgb(float3(203, 166, 247));
    if (x < LEFT_INSET || x >= float(d.viewport_size_pixels.x) - LEFT_INSET)
        return float4(bg, background.a);
    for (int i = 0; i < 7; ++i) {
        int column = columns - 4 - OFFSETS[i];
        if (column < 0) continue;
        float start = LEFT_INSET + float(column) * cw;
        float mx = (start + 0.5 * cw) * pixel.x;
        int left = decode(t, float2(mx, sample_y), 1);
        int right = decode(t, float2(mx + cw * pixel.x, sample_y), 2);
        int target_left = decode(t, float2(mx + 2.0 * cw * pixel.x, sample_y), 3);
        int target_right = decode(t, float2(mx + 3.0 * cw * pixel.x, sample_y), 2);
        if (left < int(LEFT_INSET) || right <= left || target_left < int(LEFT_INSET)
            || target_right <= target_left || float(right) > start || float(target_right) > start) continue;
        if (x >= start && x < start + 4.0 * cw) return float4(bg, background.a);
        bool under_target = x >= float(target_left) && x < float(target_right);
        // Rounded rectangle signed distance in physical pixels.
        float remainder = MOVING ? 1.0 - saturate(t.animation_progress) : 0.0;
        float2 bounds = lerp(float2(target_left, target_right), float2(left, right),
                             remainder * remainder * remainder);
        float2 center = float2(0.5 * (bounds.x + bounds.y), 0.5 * ch);
        float2 halfsize = float2(0.5 * (bounds.y - bounds.x), 0.5 * ch - 0.5);
        float radius = min(0.43 * ch, halfsize.x);
        float2 point = float2(x, (t.pos.y - bottom) / pixel.y);
        float2 q = abs(point - center) - halfsize + radius;
        float edge_distance = length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
        float fill = saturate(0.5 - edge_distance);
        bool header = x >= LEFT_INSET && x < LEFT_INSET + cw;
        if (!under_target && fill <= 0.0 && !header) return color;
        float3 base = lerp(bg, highlight, fill);
        float base_alpha = lerp(background.a, 1.0, fill);
        if (header) return float4(base, base_alpha);
        float3 old_bg = under_target ? highlight : bg;
        float3 inactive_title = linear_rgb(float3(205, 214, 244));
        float3 inactive_index = linear_rgb(float3(147, 153, 178));
        float3 active_title = linear_rgb(float3(30, 30, 46));
        float3 active_index = linear_rgb(float3(88, 91, 112));
        float3 old_title = under_target ? active_title : inactive_title;
        float3 old_index = under_target ? active_index : inactive_index;
        float title_coverage = ink_coverage(color.rgb, old_bg, old_title);
        float index_coverage = ink_coverage(color.rgb, old_bg, old_index);
        bool index = distance(color.rgb, lerp(old_bg, old_index, index_coverage))
                   < distance(color.rgb, lerp(old_bg, old_title, title_coverage));
        float3 ink = index ? lerp(inactive_index, active_index, fill) : lerp(inactive_title, active_title, fill);
        float coverage = index ? index_coverage : title_coverage;
        return float4(lerp(base, ink, coverage), lerp(base_alpha, 1.0, coverage));
    }
    return color;
}
