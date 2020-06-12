// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

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
sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _NormalMap;
float4 _NormalMap_ST;
sampler2D _AOTex;
float4 _AOTex_ST;
sampler2D _MetallicTex;
float4 _MetallicTex_ST;
sampler2D _RoughnessTex;
float4 _RoughnessTex_ST;
sampler2D _MaskTex;
float4 _MaskTex_ST;
sampler2D _NoiseTex;
float4 _NoiseTex_ST;
sampler2D _DetailTex;
float4 _DetailTex_ST;
sampler2D _DetailNormalMap;
float4 _DetailNormalMap_ST;
samplerCUBE _EvoCube;

float _Brightness;
float _Saturation;
float _Contrast;
//float4 _LightColor0;
fixed4 _Color;
float4 _SSSColor;

float _ShadowStrength;
half _AOScale;
float4 _Roughness;
float4 _Metallic;
float4 _BumpScale;
float4 _Specular;
float4 _SpecularTint;
float4 _Sheen;
float4 _SheenTint;
float4 _ClearcoatGloss;
float4 _Clearcoat;
float4 _Subsurface;
float4 _Anisotropic;

int _ScatterNum;
float4 _ScatterColor;
float _ScatterPower;
float _ScatterScale;
float _ScatterRadius;
float _ScatterThickness;
float _ScatterBase;

float _DetailBumpScale;
float _DetailScale;
float _DetailThickness;

struct v2f
{
    float4 pos : SV_POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    float3 tangent : TEXCOORD3;
    float3 binormal : TEXCOORD4;
    float3 vertex : TEXCOORD5;
    SHADOW_COORDS(6)
};            

v2f vert (appdata_tan v)
{
    v2f o;
    o.vertex = v.vertex;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normal = UnityObjectToWorldNormal(v.normal);
    //转换法线坐标到世界空间，直接使用_Object2World转换法线，不能保证转换后法线依然与模型垂直  
    //o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
    o.tangent = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
    o.binormal = cross(o.normal, o.tangent) * v.tangent.w;
    TRANSFER_SHADOW(o);
    return o;
}

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


 

