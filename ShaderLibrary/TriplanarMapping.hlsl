#ifndef KACPER119P_SHADERS_TRIPLANAR_MAPPING_INCLUDED
#define KACPER119P_SHADERS_TRIPLANAR_MAPPING_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

struct TriplanarUV
{
    float2 x;
    float2 y;
    float2 z;
};

TriplanarUV GetTriplanarUV(float3 positionWS)
{
    TriplanarUV result;
    result.x = positionWS.zy;
    result.y = positionWS.xz;
    result.z = positionWS.xy;
    return result;
}

TriplanarUV TransformUVTriplanar(TriplanarUV uv, float4 st)
{
    uv.x = uv.x * st.xy + st.zw;
    uv.y = uv.y * st.xy + st.zw;
    uv.z = uv.z * st.xy + st.zw;
    return uv;
}

TriplanarUV GetTriplanarUV(float3 positionWS, float4 st)
{
    return TransformUVTriplanar(GetTriplanarUV(positionWS), st);
}

#define TRANSFORM_TEX_TRIPLANAR(uv, name) (TransformUVTriplanar(uv, name##_ST))

float3 GetTriplanarWeights(float3 normalWS)
{
    normalWS = abs(normalWS);
    return normalWS / (normalWS.x + normalWS.y + normalWS.z);
}

float3 GetTriplanarWeights(float3 normalWS, float offset, float power)
{
    float3 result = abs(normalWS);
    result = saturate(result - offset);
    result = pow(result, power);
    return result / (result.x + result.y + result.z);
}

float4 SampleTextureTriplanar(sampler2D tex, TriplanarUV uv, float3 weights)
{
    float4 x = tex2D(tex, uv.x);
    float4 y = tex2D(tex, uv.y);
    float4 z = tex2D(tex, uv.z);
    return x * weights.x + y * weights.y + z * weights.z;
}

float3 UnpackNormalTriplanar(sampler2D tex, TriplanarUV uv, float3 weights, float3 normalWS)
{
    float3 x = UnpackNormal(tex2D(tex, uv.x));
    float3 y = UnpackNormal(tex2D(tex, uv.y));
    float3 z = UnpackNormal(tex2D(tex, uv.z));
    return normalize(x * weights.x + y * weights.y + z * weights.z);
}

#endif
