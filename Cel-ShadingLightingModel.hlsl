#ifndef CEL_SHADING_LIGHTING_MODEL
#define CEL_SHADING_LIGHTING_MODEL

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
    const half3 attenuatedColor = light.color * attenuation;
    const half3 diffuse = attenuatedColor * saturate(dot(data.normalWS, light.direction));
    return step(0.1, diffuse);
}

half3 CalculateSpecular(const Light light, const half attenuation, const CelShadingLightData data)
{
    half3 specular = pow(saturate(dot(data.normalWS, normalize(light.direction + data.viewDirWS))),
                         220 / data.glossiness);
    specular = step(0.9, specular);
    specular *= light.color * attenuation;
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
    half3 lightDiffuse = 0;
    half3 specular = 0;

    for (uint i = 0; i < additionalLightCount; ++i)
    {
        const Light light = GetAdditionalLight(i, lightData.positionWS);
        #ifdef _ADDITIONAL_LIGHT_SHADOWS
        const half attenuation = light.distanceAttenuation * AdditionalLightRealtimeShadow(
            i, lightData.positionWS, light.direction);
        #else
        const half attenuation = light.distanceAttenuation;
        #endif
        const half3 diffuse = CalculateDiffuse(light, attenuation, lightData);
        specular += CalculateSpecular(light, attenuation, lightData);
        lightDiffuse += diffuse;
    }

    const Light light = GetMainLight(lightData.shadowCoord);
    const half attenuation = light.distanceAttenuation * light.shadowAttenuation;
    const half3 diffuse = CalculateDiffuse(light, attenuation, lightData);
    specular += CalculateSpecular(light, attenuation, lightData);
    lightDiffuse += diffuse;

    const half3 ambientLight = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    lightDiffuse = max(lightDiffuse, ambientLight);

    return min(1, lightDiffuse * lightData.baseColor + specular);
}

#endif
