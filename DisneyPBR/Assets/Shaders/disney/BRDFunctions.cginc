//--------------------------
// disney Diffuse
const float PI = 3.14159265359;

inline float pow5(float f)
{
    return f * f * f * f * f;
}

float DisneyDiffuse1(float NdotV, float NdotL, float LdotH, float roughness)
{
    float fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
    // Two schlick fresnel term
    float lightScatter   = (1 + (fd90 - 1) * pow5(1 - NdotL));
    float viewScatter    = (1 + (fd90 - 1) * pow5(1 - NdotV));
    return lightScatter * viewScatter;
}

//---------------------------
//helper functions
float MixFunction(float i, float j, float x) {
	 return  j * x + i * (1.0 - x);
} 
float2 MixFunction(float2 i, float2 j, float x){
	 return  j * x + i * (1.0h - x);
}   
float3 MixFunction(float3 i, float3 j, float x){
	 return  j * x + i * (1.0h - x);
}   
float MixFunction(float4 i, float4 j, float x){
	 return  j * x + i * (1.0h - x);
} 
float sqr(float x){
	return x*x; 
}
//------------------------------


//------------------------------------------------
//schlick functions
float SchlickFresnel(float i){
    float x = clamp(1.0-i, 0.0, 1.0);
    float x2 = x*x;
    return x2 * x2* x;
}
float3 FresnelLerp1 (float3 x, float3 y, float d)
{
	float t = SchlickFresnel(d);	
	return lerp (x, y, t);
}
float4 FresnelSchlick (float4 c, float VdotH)
{
	return c + (1 - c) * exp2(-5.55473 * VdotH - 6.98316 * VdotH);
}
float3 SchlickFresnelFunction(float3 SpecularColor,float LdotH){
    return SpecularColor + (1 - SpecularColor)* SchlickFresnel(LdotH);
}

float SchlickIORFresnelFunction(float ior,float LdotH){
    float f0 = pow((ior-1)/(ior+1),2);
    return f0 +  (1 - f0) * SchlickFresnel(LdotH);
}
float SphericalGaussianFresnelFunction(float LdotH,float SpecularColor)
{	
	float power = ((-5.55473 * LdotH) - 6.98316) * LdotH;
    return SpecularColor + (1 - SpecularColor)  * pow(2,power);
}
float3 FresnelSchlick1(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
float FresnelDefault(float NdotV, float scale, float indensity)
{
    //菲尼尔公式
    float fresnel =  scale * pow(1 - NdotV, indensity);
    return fresnel;
}
float3 FresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    float f1 = float3(1.0 - roughness,1.0 - roughness,1.0 - roughness);
    return F0 + (max(f1, F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

//-----------------------------------------------



//-----------------------------------------------
//normal incidence reflection calculation
float F0 (float NdotL, float NdotV, float LdotH, float roughness){
// Diffuse fresnel
    float FresnelLight = SchlickFresnel(NdotL); 
    float FresnelView = SchlickFresnel(NdotV);
    float FresnelDiffuse90 = 0.5 + 2.0 * LdotH*LdotH * roughness;
   return  MixFunction(1, FresnelDiffuse90, FresnelLight) * MixFunction(1, FresnelDiffuse90, FresnelView);
}

//-----------------------------------------------




//-----------------------------------------------
//Normal Distribution Functions
float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / max(denom, 0.001); // prevent divide by zero for roughness=0.0 and NdotH=1.0
}
// --------------------------------------------------------------------
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
float BlinnPhongNormalDistribution(float NdotH, float specularpower, float speculargloss){
    float Distribution = pow(NdotH,speculargloss) * specularpower * 10000;
    Distribution *= (2+specularpower) / (2*3.1415926535);
    return Distribution;
}
float PhongNormalDistribution(float RdotV, float specularpower, float speculargloss){
    float Distribution = pow(RdotV,speculargloss) * specularpower;
    Distribution *= (2+specularpower) / (2*3.1415926535);
    return Distribution;
}

float BeckmannNormalDistribution(float roughness, float NdotH)
{
    float roughnessSqr = roughness;// * roughness;
    float NdotHSqr = NdotH * NdotH;
    return max(0.000001,(1.0 / (3.1415926535*roughnessSqr*NdotHSqr*NdotHSqr))* exp((NdotHSqr-1)/(roughnessSqr*NdotHSqr)));
}

float GaussianNormalDistribution(float roughness, float NdotH)
{
    float roughnessSqr = roughness*roughness;
	float thetaH = acos(NdotH);
    return exp(-thetaH*thetaH/roughnessSqr);
}

float pow2(float f)
{
    return f * f;
}

float GGX(float NdotH, float pow2roughness, float _GGX, float power)
{
    float roughnessSqr = pow2roughness * pow2roughness;
    float NdotHSqr = NdotH * NdotH;
    float TanNdotHSqr = (1 - NdotHSqr)/NdotHSqr;
    return pow2(pow2roughness) * _GGX / (UNITY_PI * (pow2(pow2roughness) - 1) * (pow2(NdotH) + 1) + power);
}

float GGXNormalDistribution(float roughness, float NdotH)
{
    float roughnessSqr = roughness*roughness;
    float NdotHSqr = NdotH*NdotH;
    float TanNdotHSqr = (1-NdotHSqr)/NdotHSqr;
    float specular = (1.0/3.1415926535) * sqr(roughness/(NdotHSqr * (roughnessSqr + TanNdotHSqr)));
    return smoothstep(0.01,0.5, specular);
//    float denom = NdotHSqr * (roughnessSqr-1)
}

float TrowbridgeReitzNormalDistribution(float NdotH, float roughness){
    float roughnessSqr = roughness*roughness;
    float Distribution = NdotH*NdotH * (roughnessSqr-1.0) + 1.0;
    return roughnessSqr / (3.1415926535 * Distribution*Distribution);
}

float TrowbridgeReitzAnisotropicNormalDistribution(float anisotropic, float NdotH, float HdotX, float HdotY){
	float aspect = sqrt(1.0h-anisotropic * 0.9h);
	float X = max(.001, sqr(1.0-_Glossiness)/aspect) * 5;
 	float Y = max(.001, sqr(1.0-_Glossiness)*aspect) * 5;
    return 1.0 / (3.1415926535 * X*Y * sqr(sqr(HdotX/X) + sqr(HdotY/Y) + NdotH*NdotH));
}

float WardAnisotropicNormalDistribution(float anisotropic, float NdotL, float NdotV, float NdotH, float HdotX, float HdotY){
    float aspect = sqrt(1.0h-anisotropic * 0.9h);
    float X = max(.001, sqr(1.0-_Glossiness)/aspect) * 5;
 	float Y = max(.001, sqr(1.0-_Glossiness)*aspect) * 5;
    float exponent = -(sqr(HdotX/X) + sqr(HdotY/Y)) / sqr(NdotH);
    float Distribution = 1.0 / ( 3.14159265 * X * Y * sqrt(NdotL * NdotV));
    Distribution = smoothstep(0.01,5, Distribution);
    Distribution *= exp(exponent);
    return Distribution;
}
//--------------------------



//-----------------------------------------------
//Geometric Shadowing Functions

float ImplicitGeometricShadowingFunction (float NdotL, float NdotV){
	float Gs =  (NdotL*NdotV);       
	return Gs;
}

float AshikhminShirleyGeometricShadowingFunction (float NdotL, float NdotV, float LdotH){
	float Gs = NdotL*NdotV/(LdotH*max(NdotL,NdotV));
	return  (Gs);
}

float AshikhminPremozeGeometricShadowingFunction (float NdotL, float NdotV){
	float Gs = NdotL*NdotV/(NdotL+NdotV - NdotL*NdotV);
	return  (Gs);
}

float DuerGeometricShadowingFunction (float3 lightDirection,float3 viewDirection, float3 normalDirection,float NdotL, float NdotV){
    float3 LpV = lightDirection + viewDirection;
    float Gs = dot(LpV,LpV) * pow(dot(LpV,normalDirection),-4);
    return  (Gs);
}

float NeumannGeometricShadowingFunction (float NdotL, float NdotV){
	float Gs = (NdotL*NdotV)/max(NdotL, NdotV);       
	return  (Gs);
}

float KelemenGeometricShadowingFunction (float NdotL, float NdotV, float LdotH, float VdotH){
//	float Gs = (NdotL*NdotV)/ (LdotH * LdotH);           //this
	float Gs = (NdotL*NdotV)/(VdotH * VdotH);       //or this?
	return   (Gs);
}

float ModifiedKelemenGeometricShadowingFunction (float NdotV, float NdotL, float roughness)
{
	float c = 0.797884560802865; // c = sqrt(2 / Pi)
	float k = roughness * roughness * c;
	float gH = NdotV  * k +(1-k);
	return (gH * gH * NdotL);
}

float CookTorrenceGeometricShadowingFunction (float NdotL, float NdotV, float VdotH, float NdotH){
	float Gs = min(1.0, min(2*NdotH*NdotV / VdotH, 2*NdotH*NdotL / VdotH));
	return  (Gs);
}

float WardGeometricShadowingFunction (float NdotL, float NdotV, float VdotH, float NdotH){
	float Gs = pow( NdotL * NdotV, 0.5);
	return  (Gs);
}

float KurtGeometricShadowingFunction (float NdotL, float NdotV, float VdotH, float alpha){
	float Gs =  (VdotH*pow(NdotL*NdotV, alpha))/ NdotL * NdotV;
	return  (Gs);
}

//SmithModelsBelow
//Gs = F(NdotL) * F(NdotV);

float WalterEtAlGeometricShadowingFunction (float NdotL, float NdotV, float alpha){
    float alphaSqr = alpha*alpha;
    float NdotLSqr = NdotL*NdotL;
    float NdotVSqr = NdotV*NdotV;
    float SmithL = 2/(1 + sqrt(1 + alphaSqr * (1-NdotLSqr)/(NdotLSqr)));
    float SmithV = 2/(1 + sqrt(1 + alphaSqr * (1-NdotVSqr)/(NdotVSqr)));
	float Gs =  (SmithL * SmithV);
	return Gs;
}

float BeckmanGeometricShadowingFunction (float NdotL, float NdotV, float roughness){
    float roughnessSqr = roughness*roughness;
    float NdotLSqr = NdotL*NdotL;
    float NdotVSqr = NdotV*NdotV;
    float calulationL = (NdotL)/(roughnessSqr * sqrt(1- NdotLSqr));
    float calulationV = (NdotV)/(roughnessSqr * sqrt(1- NdotVSqr));
    float SmithL = calulationL < 1.6 ? (((3.535 * calulationL) + (2.181 * calulationL * calulationL))/(1 + (2.276 * calulationL) + (2.577 * calulationL * calulationL))) : 1.0;
    float SmithV = calulationV < 1.6 ? (((3.535 * calulationV) + (2.181 * calulationV * calulationV))/(1 + (2.276 * calulationV) + (2.577 * calulationV * calulationV))) : 1.0;
	float Gs =  (SmithL * SmithV);
	return Gs;
}

float GGXGeometricShadowingFunction (float NdotL, float NdotV, float roughness){
    float roughnessSqr = roughness*roughness;
    float NdotLSqr = NdotL*NdotL;
    float NdotVSqr = NdotV*NdotV;
    float SmithL = (2 * NdotL)/ (NdotL + sqrt(roughnessSqr + ( 1-roughnessSqr) * NdotLSqr));
    float SmithV = (2 * NdotV)/ (NdotV + sqrt(roughnessSqr + ( 1-roughnessSqr) * NdotVSqr));
	float Gs =  (SmithL * SmithV) ;
	return Gs;
}

float SchlickGeometricShadowingFunction (float NdotL, float NdotV, float roughness)
{
    float roughnessSqr = roughness*roughness;
	float SmithL = (NdotL)/(NdotL * (1-roughnessSqr) + roughnessSqr);
	float SmithV = (NdotV)/(NdotV * (1-roughnessSqr) + roughnessSqr);
	return (SmithL * SmithV); 
}

float SchlickBeckmanGeometricShadowingFunction (float NdotL, float NdotV, float roughness){
    float roughnessSqr = roughness*roughness;
    float k = roughnessSqr * 0.797884560802865;
    float SmithL = (NdotL)/ (NdotL * (1- k) + k);
    float SmithV = (NdotV)/ (NdotV * (1- k) + k);
	float Gs =  (SmithL * SmithV);
	return Gs;
}

float SchlickGGXGeometricShadowingFunction (float NdotL, float NdotV, float roughness){
    float k = roughness / 2;
    float SmithL = (NdotL)/ (NdotL * (1- k) + k);
    float SmithV = (NdotV)/ (NdotV * (1- k) + k);
	float Gs =  (SmithL * SmithV);
	return Gs;
}


float SmithJoint (float NdotL, float NdotV, float roughness){
    float k = UNITY_PI / 2;
    float SmithL = (NdotL)/ (NdotL * (1- k) + k);
    float SmithV = (NdotV)/ (NdotV * (1- k) + k);
	float Gs =  (SmithL * SmithV);
	return Gs;
}