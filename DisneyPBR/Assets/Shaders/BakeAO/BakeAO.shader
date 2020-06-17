// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
*Hi, I'm Lin Dong,
*this shader is about human skin's real time rendering in unity3d
*if you want to get more detail please enter my blog http://blog.csdn.net/wolf96
*/
Shader "AO/BakeAo" 
{
	Properties{
	    _MainTex("Base (RGB)", 2D) = "white" {}
	    _SampleDirCount("Sample Dir Count", int) = 2
	    _TriangleCount("Triangle Count", int) = 2
	    _AOTracingRadius("AO Traceing Radius", float) = 1
	    _AOStrength("AO Strength", float) = 1
    }
	SubShader
	{
		pass
		{
            Tags{ "LightMode" = "ForwardBase" }
            ZWrite on
            Cull Back
    
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
    
            #define PIE 3.1415926535
            
            uniform sampler2D _MainTex;
            float4 _MainTex_ST;
            
            uniform int _TriangleCount;
            uniform float3 _TriangleX[255];
            uniform float3 _TriangleY[255];
            uniform float3 _TriangleZ[255];
            
            int _SampleDirCount;
            float _AOTracingRadius;
            
            float _AOStrength;
            
            struct appdata_c
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float4 vertex : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 binormal : TEXCOORD4;
            };
            
            v2f vert(appdata_c v) 
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float2 uv = v.uv;
                uv.y = 1 - v.uv.y;
                o.vertex = float4(uv * 2 - 1, 0, 1);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
                o.binormal = cross(o.normal, o.tangent) * v.tangent.w;
                return o;
            }
    
            float4 frag(v2f i) :COLOR
            {
                //return float4(1,1,1,1);
                /*
                float aovalue = 0;
                for (int s = 0; s < (int)_SampleDirCount; s++)
                {
                    float3 sampleDir = float3(0.5,0.5,0.5);
                    sampleDir = normalize(sampleDir);
                    float3 objDir = i.tangent * sampleDir.x + i.binormal * sampleDir.y + i.normal * sampleDir.z;
                    float currentLength = _AOTracingRadius;
                    for (int j = 0; j < (int)_TriangleCount; j++)
                    {
                        float3 p0 = _TriangleX[j].xyz;
                        float3 p1 = _TriangleY[j].xyz;
                        float3 p2 = _TriangleZ[j].xyz;
                        float raylength;
                        bool result = RayTriangleTest(objDir, i.pos, p0, p1, p2, raylength);
                        if (result && raylength < currentLength)
                        {
                            currentLength = raylength;
                        }
                    }
                    float ao = clamp(currentLength, 0, _AOTracingRadius) / _AOTracingRadius;
                    aovalue += ao;
                }
                aovalue /= _SampleDirCount;
                aovalue = pow(aovalue, _AOStrength);
                */
                return i.vertex;
            }
            
            ENDCG
	    }
	}
}
