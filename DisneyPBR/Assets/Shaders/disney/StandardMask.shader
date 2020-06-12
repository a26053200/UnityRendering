/**
    baseColor（固有色）：表面颜色，通常由纹理贴图提供。
    subsurface（次表面）：使用次表面近似控制漫反射形状。
    metallic（金属度）：金属（0=电介质，1=金属）。这是两种不同模型之间的线性混合。金属模型没有漫反射成分，并且还具有等于基础色的着色入射镜面反射。
    specular（镜面反射强度）：入射镜面反射量。用于取代折射率。
    specularTint（镜面反射颜色）：对美术控制的让步，用于对基础色（basecolor）的入射镜面反射进行颜色控制。掠射镜面反射仍然是非彩色的。
    roughness（粗糙度）：表面粗糙度，控制漫反射和镜面反射。
    anisotropic（各向异性强度）：各向异性程度。用于控制镜面反射高光的纵横比。（0=各向同性，1=最大各向异性。）
    sheen（光泽度）：一种额外的掠射分量（grazing component），主要用于布料。
    sheenTint（光泽颜色）：对sheen（光泽度）的颜色控制。
    clearcoat（清漆强度）：有特殊用途的第二个镜面波瓣（specular lobe）。
    clearcoatGloss（清漆光泽度）：控制透明涂层光泽度，0=“缎面（satin）”外观，1=“光泽（gloss）”外观。

**/

Shader "PBR/DisneyPrincipledBRDF/StandardMask.Shader"
{
    Properties
    {
        _Brightness        ("Brightness",        float) = 1
        //_Saturation        ("Saturation",        float) = 1
        //_Contrast          ("Contrast",        float) = 1
        
        _Color ("Color", Color) = (1,1,1,1)
        [HideInInspector] _ShadowStrength      ("Unity Shadow Strength",         float) = 1
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalMap("Normal",2D) = "bump"{}//此处必须填写bump，否则在没有法线贴图的情况下，会出错
        _BumpScale("bump scale", Range(0,2)) = 1
        //_AOTex("AO",2D) = "white"{}
        //_MetallicTex ("Metallic (RGB)", 2D) = "white" {}
        //_RoughnessTex("Roughness",2D) = "white"{}
        _NoiseTex("Noise",2D) = "white"{}
        _MaskTex("Mask r(Roughness) g(Metallic) b(AO) a(Skin Split)",2D) = "white"{}
        //_AOScale        ("AO Scale",        Vector) = (1,1,1,1)
        _EvoCube("Envo CubeMp", Cube) = ""{}

       
        
        [Enum(DisneyPBR.PBRMaterial)]
        _Mat ("Selet PBR Material", Float) = 1
        
        [HideInInspector] _Metallic       ("Metallic",        Vector) = (0,0,0,0)
        [HideInInspector] _Roughness      ("Smoothness",      Vector) = (0,0,0,0)
        [HideInInspector] _Specular       ("Specular",        Vector) = (0,0,0,0)
        [HideInInspector] _SpecularTint   ("SpeculatTint",    Color) = (1,1,1,1)
        [HideInInspector] _Sheen          ("Sheen",           Vector) = (0,0,0,0)
        [HideInInspector] _SheenTint      ("SheenTint",       Color) = (1,1,1,1)
        [HideInInspector] _Clearcoat      ("Clearcoat",       Vector) = (0,0,0,0)
        [HideInInspector] _ClearcoatGloss ("ClearcoatGloss",  Vector) = (0,0,0,0)
        [HideInInspector] _Subsurface     ("Subsurface",      Vector) = (0,0,0,0)
        [HideInInspector] _Anisotropic    ("Anisotropic",     Vector) = (0,0,0,0)

        [HideInInspector] _SSSEnable      ("SSS Enleab",         float) = 1
        [HideInInspector] _SSSColor       ("SSS Color",          Color) = (1,1,1,1)
        [HideInInspector] _ScatterNum     ("Scatter Num",        Range(1, 100)) = 8
        [HideInInspector] _ScatterPower   ("Scatter Power",      Range(0.01,1)) = 1
        [HideInInspector] _ScatterScale   ("Scatter Scale",      Range(0,1)) = 1
        [HideInInspector] _ScatterRadius  ("Scatter Radius",     Range(-5,5)) = 1
        [HideInInspector] _ScatterThickness("Scatter Thickness", Range(0, 1)) = 1
        
        [HideInInspector] _DetailTex        ("Detail (RGB)", 2D) = "white" {}
        [HideInInspector] _DetailBumpScale  ("Detail Bump Scale",float) = 1
        [HideInInspector] _DetailScale      ("Detail Scale",float) = 1
        [HideInInspector] _DetailThickness  ("Detail Thickness",float) = 1
        [HideInInspector] _DetailNormalMap  ("Detail Normal",2D) = "bump"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        Stencil{
            Ref 5
            Comp Always
            Pass Replace
        }
        
        Pass{
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            //确保光照衰减等光照变量可以被正确赋值
            //#pragma multi_compile_fwdbase
            // compile shader into multiple variants, with and without shadows
            // (we don't care about any lightmaps yet, so skip these variants)
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            //Disney PBR
            #include "Disney_Base.cginc"
            #include "Disney_Fun.cginc"
            
            float _SSSEnable;
            
            float3 MatertalFrag(float3 L, float3 V, float3 N, float3 X, float3 Y, int index,float4 albedo, float4 roughness)
            {
                float metallic       = _Metallic[index];
                float sheen          = _Sheen[index];
                float specular       = _Specular[index];
                float subsurface     = _Subsurface[index];
                float clearcoat      = _Clearcoat[index];
                float clearcoatGloss = _ClearcoatGloss[index];
                float anisotropic    = _Anisotropic[index];
                float3 brdf = BRDF(L,V,N,X,Y,_Color.rgb * albedo.rgb,
                        metallic, roughness,
                        specular, _SpecularTint.rgb,
                        sheen, _SheenTint.rgb,
                        clearcoat, clearcoatGloss,
                        subsurface, anisotropic);
                return brdf;
            }
            
            float CalcRoughness(int index, float4 mask)
            {
                float roughness = 1 - _Roughness[index];
                //roughness = 1 - (roughness * roughness);
                //roughness = roughness * roughness;// * (1 - mask.r);
                return (1 - _Roughness[index]);
            }
            
            float4 frag (v2f i) : SV_TARGET
            {
                //Mask
                float4 mask = tex2D(_MaskTex, i.uv);
                float3 N = FetchFragmentNormal(i, _BumpScale, _NormalMap, i.uv);
                N = BlendNormal(_DetailTex, TRANSFORM_TEX(i.uv, _DetailTex), N, _DetailBumpScale);
                float3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos,_WorldSpaceLightPos0.w));
                float3 V = normalize( _WorldSpaceCameraPos.xyz - i.worldPos);
                float3 VR = normalize(reflect( -V, N ));
                float3 X = i.tangent;
                float3 Y = i.binormal;
                
                float NdotL = max(dot(N,L),0.0);
                float diffuse = NdotL * 0.5 + 0.5;
                
                fixed4 evo = texCUBE(_EvoCube, normalize(i.vertex.xyz));
                
                fixed shadow = lerp(1,SHADOW_ATTENUATION(i),_ShadowStrength);
                //Attenuation
                //float attenuation = LIGHT_ATTENUATION(i);
                //occlusion
                float occlusion = 1;
                
                //Get Unity Scene lighting data
                //UnityGI gi =  GetUnityGI(_LightColor0.rgb, L, N, V, VR, attenuation, roughness, i.worldPos.xyz, occlusion);
                //float3 indirectDiffuse = gi.indirect.diffuse.rgb ;
                //float3 indirectSpecular = gi.indirect.specular.rgb;
                //float3 attenColor = attenuation * gi.light.color;
                
                float4 albedo = tex2D (_MainTex, i.uv);
                //return float4(albedo.rgb * shadow, 1);
                float cloth_roughness = CalcRoughness(0, mask);
                UnityGI cloth_gi = GetUnityGI(_LightColor0.rgb, L, N, V, VR, 1, cloth_roughness, i.worldPos.xyz, occlusion);
                float3 cloth = MatertalFrag(L, V, N, X, Y, 0, albedo, cloth_roughness);
                float3 cloth_indirectSpecualr = IndirectSpecualr(L, V, N, cloth_roughness, _Metallic[0], albedo.rgb,_SpecularTint.rgb, evo);
                cloth += cloth_indirectSpecualr;
                
                float skin_roughness = CalcRoughness(1, mask);
                UnityGI skin_gi = GetUnityGI(_LightColor0.rgb, L, N, V, VR, 1, skin_roughness, i.worldPos.xyz, occlusion);
                float3 skin  = MatertalFrag(L, V, N, X, Y, 1, albedo, skin_roughness);
                float3 skin_indirectSpecualr = IndirectSpecualr(L, V, N, skin_roughness, _Metallic[1], albedo.rgb,_SpecularTint.rgb, evo);
                skin += skin_indirectSpecualr;
                //SSS
                //float3 sss = 0;
                //if(_ScatterThickness > 0)
                //{
                    //sss = SSS(L,V,N,skin_gi.light.color,_ScatterNum, _ScatterRadius, _ScatterPower,_ScatterScale, _SSSColor.rgb);
                    //sss = lerp(0, sss, mask.a);
                    //sss = lerp(0, sss, _ScatterThickness);
                //}
                
                float3 final = lerp(cloth * cloth_gi.light.color, skin * skin_gi.light.color, mask.a);
                
                //final = CalculateBrightness(final, _Brightness);
                //final = CalculateSaturationAndContrast(final, _Saturation, _Contrast);
                //final =  diffuse * final + sss;
                //Detail
                //float4 detailCol = tex2D(_DetailTex, TRANSFORM_TEX(i.uv, _DetailTex));
                //float3 dN = FetchFragmentNormal(i, _DetailBumpScale, _DetailNormalMap, TRANSFORM_TEX(i.uv, _DetailNormalMap));
                //float dDiffuse = max(dot(dN,L),0.0) * 0.4 + 0.6;
                //float3 detail = lerp(1, LerpWhiteTo(detailCol.rgb * unity_ColorSpaceDouble.rgb * dDiffuse, _DetailScale), _DetailThickness * 0.5);
                //final = lerp(final, final * detail, mask.a);
                
                return float4(final, 1);
            }
            ENDCG
        }
        // shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        /*
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f { 
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
        */
    }
    CustomEditor "DisneyPBR.DisneyShaderGUI"
    FallBack "Diffuse"
}
