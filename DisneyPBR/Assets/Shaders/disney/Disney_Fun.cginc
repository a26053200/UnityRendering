
const float PI = UNITY_PI;

float sqr(float x) { return x*x; }

inline float pow2(float res){
    return res * res;
}

inline float pow5(float res){
    return pow2(res) * pow2(res) * res;
}

float SchlickFresnel(float u)
{
    float m = clamp(1.0f-u, 0, 1.0f);
    float m2 = m*m;
    return m2*m2*m; // pow(m,5)
}

float GTR1(float NdotH, float a)
{
    if (a >= 1) return 1/UNITY_PI;
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return (a2-1) / (UNITY_PI*log(a2)*t);
}

float GTR2(float NdotH, float a)
{
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return a2 / (UNITY_PI * t * t);
}

float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
    return 1.0f / (UNITY_PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
}

float smithG_GGX(float NdotV, float alphaG)
{
    float a = alphaG * alphaG;
    float b = NdotV*NdotV;
    return 1.0f / (NdotV + sqrt(a + b - a*b));
}

float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
    return 1.0f / (NdotV + sqrt( sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV) ));
}

//Specular G，Geometry Term
float SmithJoint(float NdotL, float NdotV,float r)
{
    float k = pow2(r+1) / 8;
    float g1 = NdotV / (NdotV * (1 - k) + k);
    float g2 = NdotL * (NdotL * (1 - k) + k);
    return g1 * g2;
}

//次级波，只有各向同性
//对于对清漆层进行处理的次级波瓣，Disney没有使用Smith G推导，而是直接使用固定粗糙度为0.25的GGX的G项
float G_GGX(float NdotV, float alphag)
{
    float a = alphag * alphag;
    float b = NdotV * NdotV;
    return 1.0f / (NdotV + sqrt(a + b - a * b));
}
//漫反射项
float DisneyFresnel(float NdotL,float NdotV,float LdotH,float roughness)
{
    float FL = SchlickFresnel(NdotL);
    float FV = SchlickFresnel(NdotV);
    float Fd90 = 0.5 + 2.0 * LdotH*LdotH * roughness;
    float Fd = lerp(1.0f, Fd90, FL) * lerp(1.0f, Fd90, FV);//这个结果需要乘以baseColor/UNITY_PI
    return Fd;
}    

float3 mon2lin(float3 c)
{
    return float3(pow(c.r, 2.2), pow(c.g, 2.2), pow(c.b, 2.2));
}

float3 CalculateBrightness(float3 c, float brightness)
{
    return c.rgb * brightness;
}

float3 CalculateSaturationAndContrast(float3 c, float saturation, float contrast)
{
    fixed gray = 0.2123 * c.r + 0.7145 * c.g + 0.0721 * c.b;
    fixed3 grayColor = fixed3(gray, gray, gray);
    c.rgb = lerp(grayColor, c.rgb, saturation);
    c.rgb = lerp(fixed3(0.5,0.5,0.5), c.rgb, contrast);
    return c;
}

/*
basesecolor：半球反射比中反射到次表面散射的那一部分比例（去掉表面反射）
Subsurface： 控制次表面散射的形状
Metallic  0纯次表面散射（绝缘体） 1纯fresnel反射（金属） 在两种模型之间的线性过渡
Specular 高光反射的强度 其实是被用来计算F(0)
Specular tint 对specular的颜色偏移
Roughness：粗糙度，对diiff和specular都有影响
Anisotropic 各项异性程度 控制高光的方向比（从0各项同性到1最大的各项异性）
Sheen：for cloth，即对回射的增强，前面说织物的grazing 回射要强一些
Clearcoat：第二层高光分布
clearcoatGloss ：控制clearcoat的gloss
*/
float3 BRDF(float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor,
            float metallic, float roughness, 
            float specular, float3 specularTint, 
            float sheen, float3 sheenTint,
            float clearcoat, float clearcoatGloss,
            float subsurface, float anisotropic, float ggx)
{
    float NdotL = max(dot(N,L),0.0);
    float NdotV = max(dot(N,V),0.0);

    float3 H = normalize(L+V);
    float NdotH = max(dot(N,H),0.0);
    float LdotH = max(dot(L,H),0.0);

    //已知某Materail的BaseColor、Metallic、SpecularScale（默认值为0.5），欲求其diff与spec，则有如下公式：
    //float DielectricSpecular = 0.08 * _Specular;
    //float3 DiffuseColor = albedo * (1 - metallic);
    //float3 SpecularColor = DielectricSpecular * (1 - metallic) + albedo * metallic; 
    
    //float3 Cdlin = mon2lin(baseColor);
    float3 Cdlin = baseColor;
    //float3 Cdlin = DiffuseColor;
    float Cdlum = .3 * Cdlin.r + .6 * Cdlin.g  + .1 * Cdlin.b; // luminance approx.

    //float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1); // normalize lum. to isolate hue+sat
    float3 Ctint = lerp( Cdlin * (1 / Cdlum), float3(1,1,1), step(Cdlum,0));
    //float3 Ctint = baseColor;// * (1/ UNITY_PI);
    float3 CSpecR = specular * 0.08f * lerp(float3(1,1,1), Ctint, specularTint);
    float3 Cspec0 = lerp(CSpecR, Cdlin, metallic);
    float3 Csheen = lerp(float3(1,1,1), Ctint, sheenTint);
    
    //return Cdlin;
    //return Ctint;
    //return float3(Cdlum,Cdlum,Cdlum);
    //return CSpecR;
    //return Cspec0;
    //return Csheen;
    
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and lerp in diffuse retro-reflection based on roughness
    float FL = SchlickFresnel(NdotL);
    float FV = SchlickFresnel(NdotV);
    float Fd90 = 0.5 + 2.0 * LdotH * LdotH * roughness;
    float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
    //return Fd * Ctint;
    
    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    float Fss90 = LdotH * LdotH * roughness;
    float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    float sss = 1.25 * (Fss * (1.0 / (NdotL + NdotV) - .5) + .5);
    sss =  saturate(sss);
    //return sss * Cdlin;
    
    // specular
    float aspect = sqrt(1.0 - anisotropic *.9);
    float ax = max(.001, sqr(roughness) / aspect);
    float ay = max(.001, sqr(roughness) * aspect);
    float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    //float FH = SchlickFresnel(LdotH);
    float FH = DisneyFresnel(NdotL, NdotV, LdotH, roughness);
    float3 Fs = lerp(Cspec0, float3(1,1,1), FH);
    //return Fs;
    float Gs = 1;
    Gs = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
    //Gs  = SmithJoint(NdotL, NdotV, roughness);
    //Gs *= SmithJoint(NdotV, NdotV, roughness);
    //return float3(Gs, Gs, Gs);
    // sheen
    float3 Fsheen = FH * sheen * Csheen;
    
    // clearcoat (ior = 1.5 -> F0 = 0.04)
    float Dr = GTR1(NdotH, lerp(.1,.001, clearcoatGloss));
    float Fr = lerp(.04, 1.0, FH);
    float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);
    float3 Final = (1.0/UNITY_PI) * lerp(Fd, sss, subsurface) * Cdlin + Fsheen;
    //return Final;
    float GGG = (1.0 - metallic) + (Gs * Fs * Ds) + (.25 * clearcoat * Gr * Fr * Dr);
    //return GGG;
    return Final * saturate(GGG);
}

float3 SSS(float3 L, float3 V, float3 N, float3 lightColor,
    float num, float scatterRadius,float scatterPower,
    float scatterScale, float3 sssColor)
{
    float3 sss = 0;
    //float delta = 1 / num;
    //float3 lastN = N;
    //float dir = lerp(1, -1, step(scatterRadius, 0));
    //for(int i = 0; i < num; i++)
    //{
        //int index = i + 1;
        //float3 noise = tex2D(_NoiseTex, float2(index * delta,index * (1 - delta))).rgb;
        //float3 rN = normalize(noise + lastN);
        //lastN = N;
        float3 sH = normalize(L + N * scatterRadius);
        float sVdotH = pow(saturate(dot(V, -sH)), scatterPower * 100) * scatterScale;
        //sss += gi.light.color * sssColor * sVdotH * _ScatterThickness;
        sss += sssColor * sVdotH;// * (1 - occlusion);
        //sss = gi.light.color * _ScatterColor.rgb * sVdotH;// * (1 - occlusion);
    //}
    return sss;
}


float3 FresnelLerp1(float3 F0,float3 F90, float cosA){
    float t = pow5(1 - cosA);
    return lerp(F0,F90,t);
}

//Custom Indirect Specualr
float3 IndirectSpecualr(float3 L, float3 V, float3 N, float roughness, float metallic, float3 albedo, float3 specularColor, fixed4 evo)
{
    //indirect light part
    float NdotV = max(dot(N,V),0.0);
    float3 reflectDir = normalize(reflect(-V,N));
    float percetualRoughness = roughness * (1.7 - 0.7 * roughness);
    float mip = percetualRoughness * 6;
    //float3 envMap = UNITY_SAMPLE_TEXCUBE_LOD(evo.rgb, reflectDir, mip).rgb;
    float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);//区分金属非金属
    float grazing = saturate((1 - roughness) + 1 - OneMinusReflectivityFromMetallic(metallic));
    float surfaceReduction = 1 / (pow2(roughness) + 1);
    float3 indirectSpecualr = surfaceReduction * evo.rgb * FresnelLerp1(F0 * specularColor, grazing, NdotV);
    return indirectSpecualr;
}

/*
*this part is about blend normal, normal map and detail map
*and the nomal blur also in here
*this blend method is from internet
*/
float3 BlendNormal(sampler2D detailTex, float2 uv, float3 normal, float bumpScale)
{
    float3 n1 = tex2Dbias(detailTex, float4(uv, 0.0, bumpScale)) * 2 - 1;//normalBlur
    float3 n2 = normalize(normal) * 2 - 1;

    float a = 1 / (1 + n1.z);
    float b = -n1.x*n1.y*a;

    float3 b1 = float3(1 - n1.x*n1.x*a, b, -n1.x);
    float3 b2 = float3(b, 1 - n1.y*n1.y*a, -n1.y);
    float3 b3 = n1;

    if (n1.z < -0.9999999)
    {
        b1 = float3(0, -1, 0);
        b2 = float3(-1, 0, 0);
    }

    float3 r = n2.x*b1 + n2.y*b2 + n2.z*b3;

    n2 = r*0.5 + 0.5;

    n2 *= 3;
    n2 += n1;
    n2 /= 4;
    n2 = normalize(n2);
    return n2;
}

