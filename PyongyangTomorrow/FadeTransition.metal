//
//  FadeTransition.metal
//  PyongyangTomorrow
//
//  Created by Benjamin Lucas on 11/20/24.
//

#include <metal_stdlib>
using namespace metal;


float rnd (float2 st) {
    return fract(sin(dot(st.xy,
                         float2(10.5302340293,70.23492931)))*
        12345.5453123);
}

half rnd_h (half2 st) {
    return fract(sin(dot(st.xy,
                         half2(10.5302340293,70.23492931)))*
        12345.5453123);
}

half4 staticNoise (half2 st, half offset, half luminosity) {
  half staticR = luminosity * rnd_h(st * half2(offset * 2.0, offset * 3.0));
  half staticG = luminosity * rnd_h(st * half2(offset * 3.0, offset * 5.0));
  half staticB = luminosity * rnd_h(st * half2(offset * 5.0, offset * 7.0));
  return half4(staticR , staticG, staticB, 1.0);
}

float staticIntensity(float t)
{
  float transitionProgress = abs(2.0*(t-0.5));
  float transformedThreshold =1.2*(1.0 - transitionProgress)-0.1;
  return min(1.0, transformedThreshold);
}
  

  


[[ stitchable ]] half4 checkerboard(float2 position, half4 currentColor, float interval, half4 newColor) {
    const float n_noise_pixels  = 400.0;
    const float static_luminosity = 0.8;
    
    float baseMix = step(0.5, interval);
    half4 transitionMix = mix(currentColor, half4(0.0), baseMix);
    
    float2 uvStatic = floor(position * n_noise_pixels)/n_noise_pixels;

    half4 staticColor = staticNoise(half2(uvStatic), half(interval), half(static_luminosity));
    
    float staticThresh = staticIntensity(interval);
    float staticMix = step(rnd(uvStatic), staticThresh);

    return mix(transitionMix, staticColor, staticMix);
}
