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
    return fract(sin(dot(st,
                         half2(10.5302340293,70.23492931)))*
        12345.5453123);
}

half4 staticNoise (half2 st, half offset, half luminosity) {
    half staticR = luminosity * rnd_h(0.0001*st * half2(offset * 2.0, offset * 3.0));
  half staticG = luminosity * rnd_h(0.0001*st * half2(offset * 3.0, offset * 5.0));
  half staticB = luminosity * rnd_h(0.0001*st * half2(offset * 5.0, offset * 7.0));
  return half4(staticR , staticG, staticB, 1.0);
}

float staticIntensity(float t)
{
  float transitionProgress = abs(2.0*(t-0.5));
  float transformedThreshold =1.2*(1.0 - transitionProgress)-0.1;
  return min(1.0, transformedThreshold);
}
  



[[ stitchable ]] half4 staticTransition(float2 position, half4 currentColor, float interval) {
    const float n_noise_pixels  = 8.0;
    const half static_luminosity = 0.8;
    
    float baseMix = step(0.5, interval);
    half4 transitionMix = mix(currentColor, half4(0.0), baseMix);
    
    float2 uvStatic = n_noise_pixels * floor(position / n_noise_pixels);

    half4 staticColor = staticNoise(half2(uvStatic), half(interval), static_luminosity);
    
    float staticThresh = staticIntensity(interval);
    float staticMix = step(rnd(uvStatic), staticThresh);

    return mix(transitionMix, staticColor, staticMix);
}




half Hash( half2 p)
{
    half3 p2 = half3(p.xy,1.0);
    return fract(sin(dot(p2,half3(37.1,61.7, 12.4)))*38.5453123);
}

half noise(half2 p)
{
    half2 i = floor(p);
    half2 f = fract(p);
    f *= f * (3.0-2.0*f);

    return mix(
               mix(Hash(i + half2(0.,0.)), Hash(i + half2(1.,0.)),f.x),
               mix(Hash(i + half2(0.,1.)), Hash(i + half2(1.,1.)),f.x),
        f.y);
}

half fbm(half2 p)
{
    half v = 0.0;
    v += noise(p*1.)*.5;
    v += noise(p*2.)*.25;
    v += noise(p*4.)*.125;
    return v;
}

/*
half noise(half2 p) {
    return fract(sin(dot(p, half2(12.9898, 78.233))) * 4378.5453);
}

// Fractal Brownian Motion (fBM)
half fbm(half2 uv) {
    int octaves = 3;
    half persistence = 0.5;
    half amplitude = 1.0;
    half frequency = 0.1;
    half lacunarity = 2.0;
    half total = 0.0;
    half maxValue = 0.0; // Normalization factor

    for (int i = 0; i < octaves; i++) {
        total += noise(uv * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;  // Decrease amplitude
        frequency *= lacunarity;  // Increase frequency
    }

    // Normalize result to [0, 1]
    return total / maxValue;
}*/

[[ stitchable ]] half4 burnTransition(float2 position, half4 currentColor, float interval, float2 size) {
    
    //float size = 300.0;
    half2 uv = half2(position / size) - 0.5;// - iResolution.xy*.5)/iResolution.y;
    
    
    half r = 6.0*distance(half2(position), half2(0.5* size))/size.y;//, <#half2 y#>)(position, 0.5 * size);
    
    uv.x -= 1.5;

    
    half d = - r + 0.5*fbm(uv*15.1) + 7.4 * half(interval);

    if (d > 0.31){
        currentColor = half4(clamp(currentColor.rgb-(d-0.31)*10.,0.0,1.0), 1.0);
    }
    if (d > 0.47) {
        if (d < 0.8 ){

            half k = 38.0 * noise(uv*20.0);
            currentColor = half4(k * (d-0.47) * half3(1.0, 0.25, 0.0), 1.0);

            
            //(d-0.4)*33.0*0.5*(0.0+noise(100.*uv+half2(-half(interval)*2.,0.)))*half4(1.5,0.5,0.0,1.0);
        }
        else {
            currentColor = half4(0.0,0.0, 0.0,0.0);
        }
    }
    return currentColor;
}
