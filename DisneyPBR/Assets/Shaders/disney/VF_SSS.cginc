float3 MatertalFrag(float3 L, float3 V, float3 N, float3 X, float3 Y, int index,float4 albedo, float4 roughness, float thickness)
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
            subsurface, anisotropic, thickness);
    return brdf;
}

float CalcRoughness(int index, float4 mask)
{
    float roughness = saturate(1 - _Roughness[index] + mask.r);
    //roughness = 1 - (roughness * roughness);
    //roughness = roughness * roughness;// * (1 - mask.r);
    //return (1 - _Roughness[index]  * mask.r);// ;
    return roughness;
}

float4 frag (v2f i) : SV_TARGET
{
    //Sampler Texture
    float4 mask = tex2D(_MaskTex, i.uv);
    float4 albedo = tex2D (_MainTex, i.uv);
    float4 ao = tex2D (_AOTex, i.uv);
    float4 thickness = tex2D(_ThicknessTex, i.uv);
    
    float3 N0 = FetchFragmentNormal(i, _BumpScale, _NormalMap, i.uv);
    float3 N1 = FetchFragmentNormal(i, _DetailBumpScale, _DetailNormalMap, TRANSFORM_TEX(i.uv, _DetailNormalMap));
    float3 N = lerp(N0, N1, mask.a);
    //float3 N = FetchFragmentNormal(i, _BumpScale, _NormalMap, i.uv);
    //N = BlendNormal(_DetailTex, TRANSFORM_TEX(i.uv, _DetailTex), N, _DetailBumpScale);
    float3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos,_WorldSpaceLightPos0.w));
    float3 V = normalize( _WorldSpaceCameraPos.xyz - i.worldPos);
    float3 VR = normalize(reflect( -V, N ));
    float3 X = i.tangent;
    float3 Y = i.binormal;
    float3 H = normalize(L + V);
    
    float NdotL = max(dot(N,L),0.0);
    float diffuse = NdotL * 0.5 + 0.5;
    
    fixed4 evo = texCUBE(_EvoCube, normalize(i.vertex.xyz));
    
    fixed shadow = lerp(1,SHADOW_ATTENUATION(i),_ShadowStrength);
    //Attenuation
    float attenuation = LIGHT_ATTENUATION(i);
    //occlusion
    float3 occlusion = lerp(1, ao.rgb, _AOScale);
    
    //Get Unity Scene lighting data
    //UnityGI gi =  GetUnityGI(_LightColor0.rgb, L, N, V, VR, attenuation, roughness, i.worldPos.xyz, occlusion);
    //float3 indirectDiffuse = gi.indirect.diffuse.rgb ;
    //float3 indirectSpecular = gi.indirect.specular.rgb;
    //float3 attenColor = attenuation * gi.light.color;
   
    //return float4(albedo.rgb * shadow, 1);
    
    //Disney PBR
    float cloth_roughness = CalcRoughness(0, mask);
    UnityGI cloth_gi = GetUnityGI(_LightColor0.rgb, L, N, V, VR, attenuation, cloth_roughness, i.worldPos.xyz, occlusion);
    float3 cloth = MatertalFrag(L, V, N, X, Y, 0, albedo, cloth_roughness, _GGX);
    float3 cloth_indirectSpecualr = IndirectSpecualr(L, V, N, cloth_roughness, _Metallic[0], albedo.rgb,_SpecularTint.rgb, evo);
    cloth += cloth_indirectSpecualr;
    
    float skin_roughness = CalcRoughness(1, mask);
    UnityGI skin_gi = GetUnityGI(_LightColor0.rgb, L, N, V, VR, attenuation, skin_roughness, i.worldPos.xyz, occlusion);
    float3 skin  = MatertalFrag(L, V, N, X, Y, 1, albedo, skin_roughness, _GGX);
    float3 skin_indirectSpecualr = IndirectSpecualr(L, V, N, skin_roughness, _Metallic[1], albedo.rgb,_SpecularTint.rgb, evo);
    skin += skin_indirectSpecualr;
    //SSS
    //float curvature = length(fwidth(mul(unity_ObjectToWorld, float4(N, 0)))) /length(fwidth(i.worldPos)) * _CurveScale;  
    //float4 brdf = tex2D(_BRDFTex, float2((dot(N, L) * 0.5 + 0.5)* attenuation, curvature));
    
    float3 sss = 0;
    if(_ScatterThickness > 0)
    {
        float3 sssLightDir = L;
        //float3 sssLightDir = _SSSLightDir.xyz;
        sss = SSS(sssLightDir,V,i.normal,skin_gi.light.color,_ScatterNum, _ScatterRadius, _ScatterPower,_ScatterScale, _SSSColor.rgb);
        sss = lerp(0, sss, saturate(thickness.r * _ScatterThickness));
    }
    //return float4(lerp(0, sss, mask.a), 1);
    //Emission
    
    float3 final = lerp(skin_gi.light.color * cloth * occlusion, skin_gi.light.color * skin + sss , mask.a);
    final = CalculateBrightness(final, _Brightness);
    //final = CalculateSaturationAndContrast(final, _Saturation, _Contrast);
    //Detail
    //float4 detailCol = tex2D(_DetailTex, TRANSFORM_TEX(i.uv, _DetailTex));
    //float3 dN = FetchFragmentNormal(i, _DetailBumpScale, _DetailNormalMap, TRANSFORM_TEX(i.uv, _DetailNormalMap));
    //float dDiffuse = max(dot(dN,L),0.0) * 0.4 + 0.6;
    //float3 detail = lerp(1, LerpWhiteTo(detailCol.rgb * unity_ColorSpaceDouble.rgb * dDiffuse, _DetailScale), _DetailThickness * 0.5);
    //final = lerp(final, final * detail, mask.a);
    
    return float4(final, 1);
}