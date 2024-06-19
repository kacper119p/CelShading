#ifndef KACPER119P_SHADERS_UTILITY_INCLUDED
#define KACPER119P_SHADERS_UTILITY_INCLUDED

float3 ApplyNormalStrength(float3 normal, float strength)
{
    return float3(normal.rg * strength, lerp(1, normal.b, saturate(strength)));
}

float GetColorDifference(float3 a, float3 b)
{
    float redMean = (a.r + b.r) * 0.5;
    float3 difference = a - b;
    difference *= difference;
    return sqrt((2.0 + redMean) * difference.r + 4 * difference.g + (3 - redMean) * difference.b);
}

float GetColorDifference(float4 a, float4 b)
{
    return GetColorDifference(a.rgb, b.rgb);
}

#endif
