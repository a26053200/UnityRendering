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

Shader "PBR/DisneyPrincipledBRDF/StandardTexture.Shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalMap("Normal",2D) = "bump"{}//此处必须填写bump，否则在没有法线贴图的情况下，会出错
        _BumpScale("bump scale", Range(0,2)) = 1
        _MetallicTex ("Metallic (RGB)", 2D) = "white" {}
        _RoughnessTex("Roughness",2D) = "white"{}
        _AOTex("AO",2D) = "white"{}
        
        _AOScale        ("AO Scale",        Range(0, 2)) = 1
        _Metallic       ("Metallic",        Range(0,1)) = 0.0
        _Roughness      ("Smoothness",      Range(0,1)) = 0.5
        _Specular       ("Specular",        Range(0,1)) = 0.5
        _SpecularTint   ("SpeculatTint",    Color) = (1,1,1,1)
        _Sheen          ("Sheen",           Range(0,1)) = 0
        _SheenTint      ("SheenTint",       Color) = (1,1,1,1)
        _Clearcoat      ("Clearcoat",       Range(0,1)) = 1
        _ClearcoatGloss ("ClearcoatGloss",  Range(0,1)) = 1
        _Subsurface     ("Subsurface",      Range(0,1)) = 0.5
        _SSSColor       ("SSS Color",       Color) = (1,1,1,1)
        _Anisotropic    ("Anisotropic",     Range(0,1)) = 0
    }
    
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            //Disney PBR
            #include "Disney_Base.cginc"
            #include "Disney_Fun.cginc"
            
            float4 frag (v2f i) : SV_TARGET
            {
                float3 N = FetchFragmentNormal(i, _BumpScale, _NormalMap, TRANSFORM_TEX(i.uv, _NormalMap));
                float3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos,_WorldSpaceLightPos0.w));
                float3 V = normalize( _WorldSpaceCameraPos.xyz - i.worldPos);
                float3 VR = normalize(reflect( -V, N ));
                float3 X = i.tangent;
                float3 Y = i.binormal;
                
                // AO
                float4 aoTex = tex2D (_AOTex, i.uv);
                float occlusion = lerp(1, aoTex.r,_AOScale);
                // Metallic
                float4 metallicMask = tex2D(_MetallicTex, i.uv);
                float metallic = _Metallic * metallicMask.r;
                // Roughness
                float4 roughnessMask = tex2D(_RoughnessTex, i.uv);
                float roughness = 1 - (_Roughness * _Roughness);
                roughness = roughness * roughness * roughnessMask.r;
                
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.rgb;
                
                //Get Unity Scene lighting data
                UnityGI gi =  GetUnityGI(_LightColor0.rgb, L, N, V, VR, attenuation, roughness, i.worldPos.xyz, occlusion);
                float3 indirectDiffuse = gi.indirect.diffuse.rgb ;
                float3 indirectSpecular = gi.indirect.specular.rgb;
                
                float4 albedo = tex2D (_MainTex, i.uv);
                //float sheen =  (1 - mask.a) * _Sheen;
                //float specular =  (mask.a) * _Specular;
                //float subsurface =  (mask.a) * _Subsurface;
                float3 brdf = BRDF(L,V,N,X,Y,_Color.rgb,
                        metallic, roughness,
                        _Specular, _SpecularTint.rgb,
                        _Sheen, _SheenTint.rgb,
                        _Clearcoat, _ClearcoatGloss,
                        _Subsurface, _Anisotropic);
                float3 final = gi.light.color * brdf * albedo;
                return float4(final, 1);
            }
            ENDCG
        }
    }
    CustomEditor "DisneyPBR.DisneyShaderGUI"
    FallBack "Diffuse"
}
