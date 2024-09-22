Shader "Cel-Shading/Cel-Shading Triplanar"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (0.5, 0.5, 0.5,1)
        _BaseMap ("Base Map", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0, 1)
        _EmissionMap ("Emission Map", 2D) = "white" {}
        [Normal] _NormalMap ("Normal Map",2D) = "bump"{}
        _NormalStrength ("Normal Strength", Float) = 1
        _Specular ("Specular", Float) = 0.5
        _SpecularMap ("Specular Map", 2D) = "white" {}
        [KeywordEnum(Off, On)] _Rim_Highlights ("Rim Highlights", int) = 0
        [HDR] _RimHighlightsColor ("Rim Highlights Color", Color) = (1, 1, 1, 1)
        _RimHighlightsPower ("Rim Highlights Fresnel Power", Float) = 1.0
        [KeywordEnum(Object, World)] _Sampling_Space ("Sampling Space", int) = 0
        _BlendOffset ("Blend Offset", Range(0, 0.5)) = 0.25
        _BlendPower ("Blend Power", Range(1, 8)) = 2
        [KeywordEnum(Hard, Soft)] _Additional_Lights ("Lights", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2.0
    }
    SubShader
    {

        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Name "ForwardLit"
            Cull [_Cull]
            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _RIM_HIGHLIGHTS_ON
            #pragma multi_compile _SAMPLING_SPACE_OBJECT _SAMPLING_SPACE_WORLD

            #pragma multi_compile _ADDITIONAL_LIGHTS_HARD _ADDITIONAL_LIGHTS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.kacper119p.cel-shading/ShaderLibrary/Cel-ShadingLightingModel.hlsl"
            #include "Packages/com.kacper119p.cel-shading/ShaderLibrary/Utility.hlsl"
            #include "Packages/com.kacper119p.cel-shading/ShaderLibrary/TriplanarMapping.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord : TEXCOORD4;
                #endif

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS : TEXCOORD5;
                #endif

                #if _SAMPLING_SPACE_OBJECT
                float3 positionOS : TEXCOORD6;
                #endif
            };

            CBUFFER_START(UnityPerMaterial)
                half3 _BaseColor;
                half3 _EmissionColor;
                sampler2D _EmissionMap;
                float4 _EmissionMap_ST;
                sampler2D _BaseMap;
                float4 _BaseMap_ST;
                half _Specular;
                sampler2D _SpecularMap;
                float4 _Specular_Map_ST;
                sampler2D _NormalMap;
                float _NormalStrength;
                float4 _NormalMap_ST;
                half3 _RimHighlightsColor;
                float _RimHighlightsPower;
                float _BlendOffset;
                float _BlendPower;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                OUT.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                OUT.positionWS = vertexInput.positionWS;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS.xyz), IN.tangentOS.w);
                #if _SAMPLING_SPACE_OBJECT
                OUT.positionOS = IN.positionOS;
                #endif

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                IN.normalWS = normalize(IN.normalWS);
                IN.tangentWS = normalize(IN.tangentWS);
                float3x3 tangentToWorldMatrix = CreateTangentToWorld(IN.normalWS, IN.tangentWS.xyz, IN.tangentWS.w);

                #if _SAMPLING_SPACE_OBJECT
                TriplanarUV uv = GetTriplanarUV(IN.positionOS);
                #else
                TriplanarUV uv = GetTriplanarUV(IN.positionWS);
                #endif
                float3 weights = GetTriplanarWeights(IN.normalWS, _BlendOffset, _BlendPower);

                TriplanarUV normalMapUV = TRANSFORM_TEX_TRIPLANAR(uv, _NormalMap);
                float3 normalMap = UnpackNormalTriplanar(_NormalMap, normalMapUV, weights, IN.normalWS);
                normalMap = ApplyNormalStrength(normalMap, _NormalStrength);
                IN.normalWS = TransformTangentToWorld(normalMap, tangentToWorldMatrix, true);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord = IN.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                #else
                float4 shadowCoord = float4(0, 0, 0, 0);
                #endif

                const TriplanarUV baseMapUV = TRANSFORM_TEX_TRIPLANAR(uv, _BaseMap);
                const TriplanarUV specularUV = TRANSFORM_TEX_TRIPLANAR(uv, _Specular_Map);

                CelShadingLightData lightData;
                lightData.shadowCoord = shadowCoord;
                lightData.baseColor = _BaseColor * SampleTextureTriplanar(_BaseMap, baseMapUV, weights).rgb;
                lightData.normalWS = IN.normalWS;
                lightData.positionWS = IN.positionWS;
                lightData.viewDirWS = normalize(GetWorldSpaceViewDir(IN.positionWS));
                lightData.specular
                    = _Specular * SampleTextureTriplanar(_SpecularMap, specularUV, weights).r;
                #if _RIM_HIGHLIGHTS_ON
                lightData.rimHiglightsColor = _RimHighlightsColor;
                lightData.rimHighlightsPower = _RimHighlightsPower;
                #endif

                half3 color = CalculateLight(lightData);

                TriplanarUV emissionUV = TRANSFORM_TEX_TRIPLANAR(uv, _EmissionMap);
                half3 emission = _EmissionColor * SampleTextureTriplanar(_EmissionMap, emissionUV, weights).rgb;

                color += emission;

                return half4(color, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode"="DepthOnly"
            }

            ColorMask 0
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"
            ENDHLSL
        }

    }
    FallBack "Hidden/Core/FallbackError"
    CustomEditor "com.kacper119p.CelShading.Editor.Shaders.TriplanarCelShadingEditor"
}
