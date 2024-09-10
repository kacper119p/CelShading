#ifndef KACPER119P_SHADERS_UTILITY_INCLUDED
#define KACPER119P_SHADERS_UTILITY_INCLUDED

/**
 *  \brief Adjusts strength of given tangent space normal vector.
 */
float3 ApplyNormalStrength(float3 normal, float strength)
{
    return float3(normal.rg * strength, lerp(1, normal.b, saturate(strength)));
}

/**
 *  \brief Calculates Distance between two sRGB colors using redmean equation.
 *  https://en.wikipedia.org/wiki/Color_difference#sRGB
 *  \return Distance between colors in range 0.0 - 1.0 for colors with components in range 0.0 - 1.0.
 */
float GetColorDifference(float3 a, float3 b)
{
    const float redMean = (a.r + b.r) * 0.5;
    float3 difference = a - b;
    difference *= difference;
    return sqrt((2.0 + redMean) * difference.r + 4 * difference.g + (3 - redMean) * difference.b);
}

/**
 * \brief Calculates Distance between two sRGB colors using redmean equation. Ignores alpha channel.
 * https://en.wikipedia.org/wiki/Color_difference#sRGB
 * \return Distance between colors in range 0.0 - 1.0 for colors with components in range 0.0 - 1.0.
 */
float GetColorDifference(float4 a, float4 b)
{
    return GetColorDifference(a.rgb, b.rgb);
}

/**
 * \brief Gets fresnel effect strength value. It assumes that input vectors are normalized.
 */
float GetFresnelValue(float3 viewDirectionNormalized, float3 surfaceNormalVector, float power)
{
    const float result = 1.0 - saturate(dot(viewDirectionNormalized, surfaceNormalVector));
    return pow(result, power);
}

#endif
