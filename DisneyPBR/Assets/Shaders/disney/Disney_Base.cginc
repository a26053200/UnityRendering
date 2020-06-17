// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) 
{
    return cross(normal, tangent.xyz) *
        (binormalSign * unity_WorldTransformParams.w);
}

float3 FetchFragmentNormal(inout v2f i, float bumpScale, sampler2D bumpTex, float2 uv) 
{
    float3 tangentSpaceNormal = UnpackNormal(tex2D(bumpTex, uv));
    return normalize(
        tangentSpaceNormal.x * i.tangent * bumpScale +
        tangentSpaceNormal.y * i.binormal * bumpScale +
        tangentSpaceNormal.z * i.normal
    );
}
UnityGI GetUnityGI(float3 lightColor, float3 lightDirection, float3 normalDirection,
float3 viewDirection, float3 viewReflectDirection, float attenuation, float roughness, float3 worldPos, float occlusion)
{
 //Unity light Setup ::
    UnityLight light;
    light.color = lightColor;
    light.dir = lightDirection;
    light.ndotl = max(0.0h,dot( normalDirection, lightDirection));
    UnityGIInput d;
    d.light = light;
    d.worldPos = worldPos;
    d.worldViewDir = viewDirection;
    d.atten = attenuation;
    d.ambient = 0.0h;
#if UNITY_SPECCUBE_BOX_PROJRCTION
    d.boxMax[0] = unity_SpecCube0_BoxMax;
    d.boxMin[0] = unity_SpecCube0_BoxMin;
    d.probePosition[0] = unity_SpecCube0_ProbePosition;
    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.boxMax[1] = unity_SpecCube1_BoxMax;
    d.boxMin[1] = unity_SpecCube1_BoxMin;
    d.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif
    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.probeHDR[1] = unity_SpecCube1_HDR;
    Unity_GlossyEnvironmentData ugls_en_data;
    ugls_en_data.roughness = roughness;
    ugls_en_data.reflUVW = viewReflectDirection;
    UnityGI gi = UnityGlobalIllumination(d, occlusion, normalDirection, ugls_en_data );
    return gi;
}


 

