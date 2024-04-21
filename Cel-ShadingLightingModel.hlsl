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
};

/**
 * \brief Calculates light and returns calculated color of the surface.
 * \param lightData surface parameters.
 * \return color of the surface after calculating light.
 */
half3 CalculateLight(CelShadingLightData lightData)
{
    const uint additionalLightCount = GetAdditionalLightsCount();
    half3 lightDiffuse = 0;

    half specular = 0;

    for (uint i = 0; i < additionalLightCount; ++i)
    {
        const Light light = GetAdditionalLight(i, lightData.positionWS);
        const half attenuation = light.distanceAttenuation * light.shadowAttenuation;
        half diffuse = light.color * attenuation * saturate(dot(lightData.normalWS, light.direction));
        diffuse = step(0.1, diffuse);
        
        lightDiffuse += diffuse;
    }

    const Light light = GetMainLight(lightData.shadowCoord);
    const half attenuation = light.distanceAttenuation * light.shadowAttenuation;
    half diffuse = light.color * attenuation * saturate(dot(lightData.normalWS, light.direction));
    diffuse = step(0.1, diffuse);
    
    lightDiffuse += diffuse;

    const half3 ambientLight = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    lightDiffuse = max(lightDiffuse, ambientLight);

    return lightDiffuse * lightData.baseColor + step(0.1, specular);
}

#endif
