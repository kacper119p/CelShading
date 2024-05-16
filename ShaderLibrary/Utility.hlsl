#ifndef KACPER119P_SHADERS_UTILITY_INCLUDED
#define KACPER119P_SHADERS_UTILITY_INCLUDED

float3 ApplyNormalStrength(float3 normal, float strength)
{
    return float3(normal.rg * strength, lerp(1, normal.b, saturate(strength)));
}

#endif
