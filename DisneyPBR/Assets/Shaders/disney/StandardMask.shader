Shader "PBR/DisneyPrincipledBRDF/StandardMask.Shader"
{
    Properties
    {
        [HideInInspector] _Brightness        ("Brightness",        float) = 1
        //_Saturation        ("Saturation",        float) = 1
        //_Contrast          ("Contrast",        float) = 1
        
        [HideInInspector] _Color ("Color", Color) = (1,1,1,1)
        [HideInInspector] _ShadowStrength      ("Unity Shadow Strength",         float) = 1
        [HideInInspector] _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [HideInInspector] _NormalMap("Normal",2D) = "bump"{}//此处必须填写bump，否则在没有法线贴图的情况下，会出错
        [HideInInspector] _BumpScale("bump scale", Range(0,2)) = 1
        [HideInInspector] _ThicknessTex("Thickness", 2D) = "white"{}
        [HideInInspector] _AOTex("AO",2D) = "white"{}
        [HideInInspector] _AOScale        ("AO Scale",        Range(0,1)) = 1
        //[HideInInspector] _MetallicTex ("Metallic (RGB)", 2D) = "white" {}
        //[HideInInspector] _RoughnessTex("Roughness",2D) = "white"{}
        [HideInInspector] _NoiseTex("Noise",2D) = "white"{}
        [HideInInspector] _MaskTex("Mask r(Roughness) g(Metallic) b(AO) a(Skin Split)",2D) = "white"{}
        
        [HideInInspector] _EvoCube("Envo CubeMp", Cube) = ""{}
        
        [Enum(DisneyPBR.PBRMaterial)]
        _Mat ("Selet PBR Material", Float) = 1
        
        [HideInInspector] _GGX            ("GGX",             Range(0, 2)) = 1
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

        [HideInInspector] _SSSLightDir    ("SSS Light Dir",    Vector) = (0,0,0,0)
        [HideInInspector] _SSSColor       ("SSS Color",          Color) = (1,1,1,1)
        [HideInInspector] _ScatterNum     ("Scatter Num",        Range(1, 100)) = 8
        [HideInInspector] _ScatterPower   ("Scatter Power",      Range(0.001,0.1)) = 1
        [HideInInspector] _ScatterScale   ("Scatter Scale",      Range(0,1)) = 1
        [HideInInspector] _ScatterRadius  ("Scatter Radius",     Range(0.0001,2)) = 1
        [HideInInspector] _ScatterThickness("Scatter Thickness", Range(0, 10)) = 1
        
        [HideInInspector] _DetailTex        ("Detail (RGB)", 2D) = "white" {}
        [HideInInspector] _DetailBumpScale  ("Detail Bump Scale",float) = 1
        [HideInInspector] _DetailScale      ("Detail Scale",float) = 1
        [HideInInspector] _DetailThickness  ("Detail Thickness",float) = 1
        [HideInInspector] _DetailNormalMap  ("Detail Normal",2D) = "bump"{}
        
        
        _BRDFTex("BRDF (RGB)", 2D) = "white" {}
	    _CurveScale("Curvature Scale", Range(0.001, 1)) = 0.01
	    /*
        _RimPower("RimPower", Range(0.1, 0.8)) = 0.5
		_RimColor("Rim Color", Color) = (1, 1, 1, 1)
		_RimTex("Rim (RGB)", 2D) = "white" {}
	    _FrontRimPower("Front RimPower", Range(0.1, 0.8)) = 0.5
		_FrontRimColor("Front Rim Color", Color) = (1, 1, 1, 1)
		_FrontRimTex("Front Rim (RGB)", 2D) = "white" {}

	    _SSSPower("SSSPower", Range(0.1, 15)) = 0.5
		_SSSFrontTex("Front SSS (RGB)", 2D) = "white" {}
	    _SSSBackTex("Back SSS (RGB)", 2D) = "white" {}
	    
	    _GL("Gloss", Range(0, 0.1)) = 0.05
	    */
	    
    }
    
    CGINCLUDE
        
        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        #include "Lighting.cginc"
        
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
        sampler2D _ThicknessTex;
        float4 _ThicknessTex_ST;
        samplerCUBE _EvoCube;
        
        float _Brightness;
        float _Saturation;
        float _Contrast;
        //float4 _LightColor0;
        fixed4 _Color;
        
        
        float _ShadowStrength;
        float _AOScale;
        
        float _GGX;
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
        float4 _SSSColor;
        float4 _SSSLightDir;
        float _ScatterPower;
        float _ScatterScale;
        float _ScatterRadius;
        float _ScatterThickness;
        float _ScatterBase;
        
        float _DetailBumpScale;
        float _DetailScale;
        float _DetailThickness;
        
        float _RimPower;
        float4 _RimColor;
        uniform sampler2D _RimTex;
        
        float _FrontRimPower;
        float4 _FrontRimColor;
        uniform sampler2D _FrontRimTex;
        
        float _SSSPower;
        uniform sampler2D _SSSFrontTex;
        uniform sampler2D _SSSBackTex;
                    
        uniform sampler2D _BRDFTex;
        float _CurveScale;
        float _GL;
        
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
        
    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        ZWrite on
        Cull Back
        
        Stencil{
            Ref 5
            Comp Always
            Pass Replace
        }
        
        Pass{
            Tags{"LightMode" = "ForwardBase"}
            //Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            //Disney PBR
            #include "Disney_Base.cginc"
            #include "Disney_Fun.cginc"
            #include "VF_SSS.cginc"
            ENDCG
        }
        
        Pass{
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            //Disney PBR
            #include "Disney_Base.cginc"
            #include "Disney_Fun.cginc"
            #include "VF_SSS.cginc"
            ENDCG
        }
        
    }
    CustomEditor "DisneyPBR.DisneyShaderGUI"
    FallBack "Diffuse"
}
