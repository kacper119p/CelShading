#ifndef KACPER119P_SHADERS_TRIPLANAR_MAPPING_INCLUDED
#define KACPER119P_SHADERS_TRIPLANAR_MAPPING_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

/**
 * \brief UV for triplanar mapping.
 */
struct TriplanarUV
{
    float2 x;
    float2 y;
    float2 z;
};

/**
 * \brief Converts given position to TriplanarUV.
 * \param position Position in object/world space.
 * \return TriplanarUV
 */
TriplanarUV GetTriplanarUV(float3 position)
{
    TriplanarUV result;
    result.x = position.zy;
    result.y = position.xz;
    result.z = position.xy;
    return result;
}

/**
 * \brief Applies texture tiling and offset settings to triplanarUV.
 * \param uv Texture coordinates.
 * \param st Texture tiling and offset settings.
 * \return Transformed UV.
 */
TriplanarUV TransformUVTriplanar(TriplanarUV uv, float4 st)
{
    uv.x = uv.x * st.xy + st.zw;
    uv.y = uv.y * st.xy + st.zw;
    uv.z = uv.z * st.xy + st.zw;
    return uv;
}

/**
 * \brief Converts given position to TriplanarUV and applies texture tiling and offset settings to triplanarUV.
 * \param position Position in object/world space.
 * \param st Texture tiling and offset settings.
 * \return Transformed TriplanarUV.
 */
TriplanarUV GetTriplanarUV(float3 position, float4 st)
{
    return TransformUVTriplanar(GetTriplanarUV(position), st);
}

/**
 * \brief Applies texture tiling and offset settings to triplanarUV. Exists to fit with build in Unity conventions.
 * \param uv Texture coordinates.
 * \param name Used texture.
 */
#define TRANSFORM_TEX_TRIPLANAR(uv, name) (TransformUVTriplanar(uv, name##_ST))

/**
 * \brief Calculates direction weights for triplanar mapping.
 * \param normalWS Normal vector in world space (assumed to be normalized).
 * \return 
 */
float3 GetTriplanarWeights(float3 normalWS)
{
    normalWS = abs(normalWS);
    return normalWS / (normalWS.x + normalWS.y + normalWS.z);
}

/**
 * \brief Calculates direction weights for triplanar mapping. Applies offset and power settings.
 * \param normalWS Normal vector in world space (assumed to be normalized).
 * \param offset Weight offset.
 * \param power Weight power.
 * \return 
 */
float3 GetTriplanarWeights(float3 normalWS, float offset, float power)
{
    float3 result = abs(normalWS);
    result = saturate(result - offset);
    result = pow(result, power);
    return result / (result.x + result.y + result.z);
}

/**
 * \brief Samples texture using triplanar mapping. 
 * \param tex Sampled texture.
 * \param uv Triplanar UV.
 * \param weights Weights for sampling.
 * \return 
 */
float4 SampleTextureTriplanar(sampler2D tex, TriplanarUV uv, float3 weights)
{
    const float4 x = tex2D(tex, uv.x);
    const float4 y = tex2D(tex, uv.y);
    const float4 z = tex2D(tex, uv.z);
    return x * weights.x + y * weights.y + z * weights.z;
}

/**
 * \brief Samples normal map texture using triplanar mapping. 
 * \param tex Sampled texture.
 * \param uv Triplanar UV.
 * \param weights Weights for sampling.
 * \return 
 */
float3 UnpackNormalTriplanar(sampler2D tex, TriplanarUV uv, float3 weights, float3 normalWS)
{
    const float3 x = UnpackNormal(tex2D(tex, uv.x));
    const float3 y = UnpackNormal(tex2D(tex, uv.y));
    const float3 z = UnpackNormal(tex2D(tex, uv.z));
    return normalize(x * weights.x + y * weights.y + z * weights.z);
}

#endif
