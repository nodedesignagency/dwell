#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The postcard's swirl stripes on the GPU (`SwirlStripesLive`): the same field as DwellUI's
// `SwirlStripes`, a uniform cubic B-spline over the designer's reference image (1716 × 2000
// px, 8 × 9 weights), placed 832 × 970 at −219.4, −15.3 on the 393-wide frame. Keep the
// numbers here and there the same.

/// The four weights of a uniform cubic B-spline at `t` (0 to 1) over `count` control points,
/// and in `first` the first of the four points they weigh.
static float4 swirlBasis(float t, int count, thread int &first) {
    int segments = count - 3;
    float u = clamp(t, 0.0f, 1.0f) * float(segments);
    first = min(int(floor(u)), segments - 1);
    float f = u - float(first);
    float f2 = f * f;
    float f3 = f2 * f;
    return float4((1.0f - f) * (1.0f - f) * (1.0f - f) / 6.0f,
                  (3.0f * f3 - 6.0f * f2 + 4.0f) / 6.0f,
                  (-3.0f * f3 + 3.0f * f2 + 3.0f * f + 1.0f) / 6.0f,
                  f3 / 6.0f);
}

/// The fitted field at a point of the 393-wide frame.
static float swirlField(float2 point, device const float *weights) {
    float u = (point.x + 219.4f) / 0.485f;
    float v = (point.y + 15.3f) / 0.485f;
    int column = 0;
    int row = 0;
    float4 across = swirlBasis(u / 1716.0f, 8, column);
    float4 down = swirlBasis(v / 2000.0f, 9, row);
    float value = 0.0f;
    for (int j = 0; j < 4; j++) {
        float line = 0.0f;
        for (int i = 0; i < 4; i++) {
            line += across[i] * weights[(row + j) * 8 + column + i];
        }
        value += down[j] * line;
    }
    return value;
}

/// Every whole step of the field, less `flow`, is a stripe's edge; a band is light where its
/// whole part is odd. Edges are softened over a third of a point, so they read as smooth as
/// drawn ones.
[[ stitchable ]] half4 swirlStripes(float2 position, half4 color, float2 size, float flow,
                                    device const float *weights, int count, half4 light, half4 deep) {
    float unit = size.x / 393.0f;
    float2 point = position / unit;
    float shift = 0.5f - flow;
    float phase = swirlField(point, weights) + shift;
    float acrossStep = swirlField(point + float2(0.5f, 0.0f), weights) + shift - phase;
    float downStep = swirlField(point + float2(0.0f, 0.5f), weights) + shift - phase;
    // How fast the field changes, per point on screen.
    float perPoint = max(length(float2(acrossStep, downStep)) * 2.0f / unit, 0.0001f);
    float away = abs(phase - round(phase)) / perPoint;
    float edge = clamp(away / 0.33f, 0.0f, 1.0f);
    float parity = floor(phase) - 2.0f * floor(phase * 0.5f);
    float lightness = parity > 0.5f ? 0.5f + 0.5f * edge : 0.5f - 0.5f * edge;
    return mix(deep, light, half4(half(lightness))) * color.a;
}
