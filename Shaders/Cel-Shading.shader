Shader "Cel-Shading/Cel-Shading"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (0.5, 0.5, 0.5,1)
        _BaseMap ("Base Map", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0, 1)
        _EmissionMap ("Emission Map", 2D) = "white" {}
        [Normal] _NormalMap ("Normal Map",2D) = "bump"{}
        _NormalStrength ("Normal Strength", Float) = 1.0
        _Specular ("Specular", Float) = 0.5
        _SpecularMap ("Specular Map", 2D) = "white" {}
        [KeywordEnum(Off, On)] _Rim_Highlights ("Rim Highlights", int) = 0
        [HDR] _RimHighlightsColor ("Rim Higlights Color", Color) = (1, 1, 1, 1)
        _RimHighlightsPower ("Rim Higlights Fresnel Power", Float) = 1.0
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

            #pragma multi_compile _ADDITIONAL_LIGHTS_HARD _ADDITIONAL_LIGHTS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.kacper119p.cel-shading/ShaderLibrary/Cel-ShadingLightingModel.hlsl"
            #include "Packages/com.kacper119p.cel-shading/ShaderLibrary/Utility.hlsl"

            struct Attributes
            {
                float2 uv : TEXCOORD0;
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                half3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord : TEXCOORD4;
                #endif

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS : TEXCOORD5;
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
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                IN.normalWS = normalize(IN.normalWS);
                IN.tangentWS = normalize(IN.tangentWS);
                float3x3 tangentToWorldMatrix = CreateTangentToWorld(IN.normalWS, IN.tangentWS.xyz, IN.tangentWS.w);

                const float2 normalMapUV = TRANSFORM_TEX(IN.uv, _NormalMap);
                float3 normalMap = UnpackNormal(tex2D(_NormalMap, normalMapUV)).rgb;
                normalMap = ApplyNormalStrength(normalMap, _NormalStrength);
                IN.normalWS = TransformTangentToWorld(normalMap, tangentToWorldMatrix, true);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord = IN.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                #else
                float4 shadowCoord = float4(0, 0, 0, 0);
                #endif

                const float2 baseMapUV = TRANSFORM_TEX(IN.uv, _BaseMap);
                const float2 specularUV = TRANSFORM_TEX(IN.uv, _Specular_Map);

                CelShadingLightData lightData;
                lightData.shadowCoord = shadowCoord;
                lightData.baseColor = _BaseColor * tex2D(_BaseMap, baseMapUV).rgb;
                lightData.normalWS = IN.normalWS;
                lightData.positionWS = IN.positionWS;
                lightData.viewDirWS = normalize(GetWorldSpaceViewDir(IN.positionWS));
                lightData.specular = _Specular * tex2D(_SpecularMap, specularUV).r;
                #if _RIM_HIGHLIGHTS_ON
                lightData.rimHiglightsColor = _RimHighlightsColor;
                lightData.rimHighlightsPower = _RimHighlightsPower;
                #endif


                half3 color = CalculateLight(lightData);

                float2 emissionUV = TRANSFORM_TEX(IN.uv, _EmissionMap);
                half3 emission = _EmissionColor * tex2D(_EmissionMap, emissionUV).rgb;

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
    CustomEditor "com.kacper119p.CelShading.Editor.Shaders.CelShadingEditor"
}
