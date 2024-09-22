Shader "Hidden/kacper119p/EdgeDetection"
{
    Properties
    {
        [HDR] _Edge_Color ("Edge Color", Color) = (0,0,0)
        _Sampling_Range ("Sampling Range", Range(0,1)) = 0.001
        _Depth_Threshold ("Depth Treshold", Float) = 0.05
        _Normal_Threshold ("Normal Treshold", Float) = 0.05
        [Toggle(_Color_Edges)] _Color_Edges ("Color Edges", int) = 0
        _Color_Threshold ("Color Threshold", Range(0.0, 1.0)) = 0.1
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
    #include "Packages/com.kacper119p.cel-shading/ShaderLibrary/Utility.hlsl"
    CBUFFER_START(UnityPerMaterial)
        TEXTURE2D_X(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);
        TEXTURE2D_X(_CameraNormalsTexture);
        SAMPLER(sampler_CameraNormalsTexture);
        float4 _BlitTexture_TexelSize;
        float3 _Edge_Color;
        float _Sampling_Range;
        float _Depth_Threshold;
        float _Normal_Threshold;
        float _Color_Threshold;
    CBUFFER_END

    float4 Fragment(Varyings input) : SV_Target
    {
        //Uses Roberts cross operator for edge detection
        float aspectRatio = _ScreenParams.x / _ScreenParams.y;
        float2 upRight = input.texcoord + float2(1, aspectRatio) * _Sampling_Range;
        float2 downRight = input.texcoord + float2(1, -aspectRatio) * _Sampling_Range;
        float2 downLeft = input.texcoord + float2(-1, -aspectRatio) * _Sampling_Range;
        float2 upLeft = input.texcoord + float2(-1, aspectRatio) * _Sampling_Range;
        float3 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord).rgb;

        #if UNITY_REVERSED_Z
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.texcoord).r;
        float depthUpRight = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, upRight).r;
        float depthDownRight = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, downRight).r;
        float depthDownLeft = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, downLeft).r;
        float depthUpLeft = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, upLeft).r;
        #else
        float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1,
            SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.texcoord).r);
        float depthUpRight = lerp(UNITY_NEAR_CLIP_VALUE, 1,
            SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, upRight).r);
        float depthDownRight = lerp(UNITY_NEAR_CLIP_VALUE, 1,
            SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, downRight).r);
        float depthDownLeft = lerp(UNITY_NEAR_CLIP_VALUE, 1,
            SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, downLeft).r);
        float depthUpLeft = lerp(UNITY_NEAR_CLIP_VALUE, 1,
            SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, upLeft).r);
        #endif

        float3 normal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, input.texcoord);
        float3 normalUpRight = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, upRight);
        float3 normalDownRight = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, downRight);
        float3 normalDownLeft = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, downLeft);
        float3 normalUpLeft = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, upLeft);

        //Modulating thresholds prevents surfaces being close to parallel to view Direction from being marked as edges.
        float3 worldPos = ComputeWorldSpacePosition(input.texcoord, depth, UNITY_MATRIX_I_VP);
        float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
        float nDotV = 1 - dot(normal, viewDir);

        float normalThreshold = pow(saturate(lerp(1, _Normal_Threshold, nDotV)), 0.25);
        float depthThreshold = _Depth_Threshold * (normalThreshold + 7) * max(FLT_EPS, depth);

        float depthDifference = length(float2(depthUpRight - depthDownLeft, depthUpLeft - depthDownRight));

        float3 normalDifference1 = normalUpRight - normalDownLeft;
        float3 normalDifference2 = normalUpLeft - normalDownRight;
        float normalDifference
            = sqrt(dot(normalDifference1, normalDifference1) + dot(normalDifference2, normalDifference2));

        float edge = max(step(normalThreshold, normalDifference), step(depthThreshold, depthDifference));

        #if _COLOR_EDGES_ON
        float3 colorUpRight = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, upRight);
        float3 colorDownRight = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, downRight);
        float3 colorDownLeft = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, downLeft);
        float3 colorUpLeft = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, upLeft);

        float3 colorDifference1 = GetColorDifference(colorUpRight, colorDownLeft);
        float3 colorDifference2 = GetColorDifference(colorUpLeft, colorDownRight);
        float colorDifference = (colorDifference1 + colorDifference2) * 0.5;
        edge = max(edge, step(_Color_Threshold, colorDifference));
        #endif

        return float4(lerp(color, _Edge_Color, edge), 1);
    }
    ENDHLSL

    SubShader
    {

        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        ZTest Always ZWrite Off Cull Off
        Pass
        {
            Name "EdgeDetection"

            HLSLPROGRAM
            #pragma multi_compile _ _COLOR_EDGES_ON
            #pragma vertex Vert
            #pragma fragment Fragment
            ENDHLSL
        }
    }
}
