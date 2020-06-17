float Lri(float3 w_P, float phi_x, float p_L_Dist, float D)
{
    float _Sigma_t = _Sigma_A + _Sigma_S;
    float L = 1 / (4 * PIE) * phi_x + 3 / (4 * PIE) * dot(w_P, -D*_Nabla * phi_x);
    float Lri = L * pow(E, -_Sigma_t* p_L_Dist);
    return Lri;
}

float fun()
{
    for (int i = 0; i < 30; i++)
    {
        w_P = normalize(float3(N.x + rand(fixed2(i*0.05, i*0.05)), N.y + rand(fixed2(-i*0.05, i*0.05)), N.z + rand(fixed2(i*0.05, -i*0.05))));
        //	float3 w_P = normalize(float3(lightDir.x + rand(i.uv_MainTex + fixed2(i*0.01, i*0.01)), lightDir.y + rand(i.uv_MainTex + fixed2(-i*0.01, i*0.01)), lightDir.z + rand(i.uv_MainTex + fixed2(i*0.01, -i*0.01))));
        Q += phase(dot(lightDir, w_P))*Lri(w_P, phi_x, p_L_Dist, D);
        Q *= _Sigma_S;
        Q1 += Q*w_P;
    }
}