#ifndef KACPER119P_SHADERS_CEL_SHADING_LIGHTING_MODEL_INCLUDED
#define KACPER119P_SHADERS_CEL_SHADING_LIGHTING_MODEL_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

/**
 * \brief Parameters for lighting calculation.
 */
struct CelShadingLightData
{
    float4 shadowCoord;
    float3 positionWS;
    float3 viewDirWS;
    half3 baseColor;
    half3 normalWS;
    half glossiness;
};

half3 CalculateDiffuse(const Light light, const half attenuation, const CelShadingLightData data)
{
    return step(0.1h, dot(data.normalWS, light.direction) * attenuation) * light.color;
}

half3 CalculateDiffuseSoft(const Light light, const half attenuation, const CelShadingLightData data)
{
    const half3 attenuatedColor = light.color * attenuation;
    return attenuatedColor * saturate(dot(data.normalWS, light.direction));
}

half3 CalculateSpecular(const Light light, const half attenuation, const CelShadingLightData data)
{
    half lightAmount = dot(data.normalWS, normalize(light.direction + data.viewDirWS));
    lightAmount = pow(saturate(lightAmount), 220.0h / data.glossiness) * attenuation;
    lightAmount = step(0.9h, lightAmount);
    half3 specular = light.color * lightAmount;
    return specular;
}

/**
 * \brief Calculates light and returns calculated color of the surface.
 * \param lightData surface parameters.
 * \return color of the surface after calculating light.
 */
half3 CalculateLight(CelShadingLightData lightData)
{
    const uint additionalLightCount = GetAdditionalLightsCount();
    half3 lightDiffuse = 0.0h;
    half3 specular = 0.0h;

    for (uint i = 0; i < additionalLightCount; ++i)
    {
        const Light light = GetAdditionalLight(i, lightData.positionWS);
        #if _ADDITIONAL_LIGHTS_HARD
        half attenuation = step(FLT_EPS, light.distanceAttenuation);
        #else
        half attenuation = light.distanceAttenuation * light.distanceAttenuation;
        #endif

        #ifdef _ADDITIONAL_LIGHT_SHADOWS
        attenuation *= AdditionalLightRealtimeShadow(i, lightData.positionWS, light.direction);
        #endif

        const half3 diffuse = CalculateDiffuse(light, attenuation, lightData);
        specular += CalculateSpecular(light, attenuation, lightData);
        lightDiffuse += diffuse;
    }

    const Light light = GetMainLight(lightData.shadowCoord);
    const half3 diffuse = CalculateDiffuse(light, light.shadowAttenuation, lightData);
    specular += CalculateSpecular(light, light.shadowAttenuation, lightData);
    lightDiffuse += diffuse;

    const half3 ambientLight = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);

    lightDiffuse = lightDiffuse + ambientLight;

    return lightDiffuse * lightData.baseColor + specular;
}

#endif
