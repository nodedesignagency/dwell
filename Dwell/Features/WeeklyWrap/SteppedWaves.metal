#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The explorer page's stepped waves on the GPU (`SteppedWavesLive`), redrawn from the
// designer's pattern image (1884 × 1977 px, placed in Figma at 628 × 659, at −117, 239 on the
// 393 × 852 frame: a third of its pixels to the point). Measured from the image's pixels, in
// points of the placed image:
//
// - Wavy stripes, grey (#DCDCDC) and white, a stripe pair every 58.55, the grey 30.67 of it.
// - Cut into columns 38.867 wide, the first edge 28.017 in. Each column's stripes are sheared
//   down 0.36 of a point for every point across it, so at every column edge they step back up
//   by about 14 (the image's own steps: 11 to 16).
// - Under the shear, the wave the stripes follow: a curve fitted through the middle of every
//   column, 611.67 long, cresting a third of the way across the placed image (two harmonics;
//   it sits within 2 of the image's own, column by column).
//
// Keep the numbers here and in `SteppedWavesLive` the same.

constant float columnWidth = 38.867f;
constant float firstColumn = 28.017f;
constant float shear = 0.36f;
constant float pitch = 58.55f;
constant float duty = 30.67f / 58.55f;
constant float wavelength = 611.67f;

/// The wave the stripes follow at `u` across the placed image, and its slope.
static float2 steppedWave(float u) {
    float theta = 2.0f * M_PI_F * u / wavelength;
    float value = 404.5f + 17.62f * cos(theta) - 76.32f * sin(theta)
        + 4.287f * cos(2.0f * theta) - 6.667f * sin(2.0f * theta);
    float slope = 2.0f * M_PI_F / wavelength * (-17.62f * sin(theta) - 76.32f * cos(theta)
        - 8.574f * sin(2.0f * theta) - 13.334f * cos(2.0f * theta));
    return float2(value, slope);
}

/// `travel`: how far the wave has rolled to the right since the page opened, in points of the
/// placed image; the columns stay put. Light and deep are drawn at full strength; the page sets
/// their opacity (Figma's 20%). The image hangs from the bottom of the screen as the design
/// places it, 613 above the bottom edge, and scales with the screen's width.
[[ stitchable ]] half4 steppedWaves(float2 position, half4 color, float2 size, float travel,
                                    half4 light, half4 deep) {
    float unit = size.x / 393.0f;
    float2 point = position / unit;
    float u = point.x + 117.0f;
    float v = point.y - (size.y / unit - 613.0f);

    float column = floor((u - firstColumn) / columnWidth);
    float across = u - firstColumn - column * columnWidth;
    float2 wave = steppedWave(u - travel);
    float edge = wave.x + shear * (across - columnWidth * 0.5f);

    // Where this point sits in its stripe pair: grey from 0 to `duty`, white after.
    float phase = (v - edge) / pitch;
    float f = phase - floor(phase);
    // How far to the nearest stripe edge, across the stripe rather than straight down.
    float down = min(min(f, 1.0f - f), abs(f - duty)) * pitch;
    float away = down / sqrt(1.0f + (wave.y + shear) * (wave.y + shear)) * unit;
    // Edges softened over a third of a point, so they read as smooth as drawn ones.
    float edgeShare = clamp(away / 0.33f, 0.0f, 1.0f);
    float greyness = f < duty ? 0.5f + 0.5f * edgeShare : 0.5f - 0.5f * edgeShare;
    return mix(light, deep, half4(half(greyness))) * color.a;
}
