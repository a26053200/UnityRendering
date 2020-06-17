using System;
using UnityEditor;
using UnityEditor.Graphs;
using UnityEngine;

namespace DisneyPBR
{
    public class DisneyShaderGUI : BaseShaderGUI
    {
        
        protected MaterialProperty _Brightness;
        protected MaterialProperty _Saturation;
        protected MaterialProperty _Contrast;
        /*
            _Metallic       ("Metallic",        Vector) = (1,1,1,1)
            _Roughness      ("Smoothness",      Vector) = (1,1,1,1)
            _Specular       ("Specular",        Vector) = (1,1,1,1)
            _SpecularTint   ("SpeculatTint",    Color) = (1,1,1,1)
            _Sheen          ("Sheen",           Vector) = (1,1,1,1)
            _SheenTint      ("SheenTint",       Color) = (1,1,1,1)
            _Clearcoat      ("Clearcoat",       Vector) = (1,1,1,1)
            _ClearcoatGloss ("ClearcoatGloss",  Vector) = (1,1,1,1)
            _Subsurface     ("Subsurface",      Vector) = (1,1,1,1)
            _Anisotropic    ("Anisotropic",     Vector) = (1,1,1,1)
         */
        protected MaterialProperty _PBRMat;
        protected MaterialProperty _NormalMap;
        protected MaterialProperty _ThicknessTex;
        protected MaterialProperty _BumpScale;
        protected MaterialProperty _MaskTex;
        protected MaterialProperty _AOTex;
        protected MaterialProperty _EvoCube;
        
        protected MaterialProperty _ShadowStrength;
        protected MaterialProperty _AOScale;
        
        protected MaterialProperty _SpecularTint;
        protected MaterialProperty _SheenTint;
        
        protected MaterialProperty _GGX;
        protected MaterialProperty _Metallic;
        protected MaterialProperty _Roughness;
        protected MaterialProperty _Specular;
        protected MaterialProperty _Sheen;
        protected MaterialProperty _Clearcoat;
        protected MaterialProperty _ClearcoatGloss;
        protected MaterialProperty _Subsurface;
        protected MaterialProperty _Anisotropic;
        
        //SSS
        protected MaterialProperty _NoiseTex;
        protected MaterialProperty _SSSLightDir;
        protected MaterialProperty _ScatterNum;
        protected MaterialProperty _SSSColor;
        protected MaterialProperty _ScatterPower;
        protected MaterialProperty _ScatterScale;
        protected MaterialProperty _ScatterRadius;
        protected MaterialProperty _ScatterThickness;
        
        //Detail
        protected MaterialProperty _DetailTex;
        protected MaterialProperty _DetailThickness;
        protected MaterialProperty _DetailNormalMap;
        protected MaterialProperty _DetailScale;
        protected MaterialProperty _DetailBumpScale;
        
        
        
        private bool isTrim;
        private bool isDrawSSS;
        private bool isDetail;
        protected override void FindProperties(MaterialProperty[] props)
        {
            base.FindProperties(props);
            _Brightness       = FindProperty("_Brightness", props);
            //_Saturation       = FindProperty("_Saturation", props);
            //_Contrast         = FindProperty("_Contrast", props);
            
            
            
            _SpecularTint     = FindProperty("_SpecularTint", props);
            _SheenTint        = FindProperty("_SheenTint", props);
            
            _PBRMat           = FindProperty("_Mat", props);
            _NormalMap        = FindProperty("_NormalMap", props);
            _ThicknessTex     = FindProperty("_ThicknessTex", props);
            _BumpScale        = FindProperty("_BumpScale", props);
            _MaskTex          = FindProperty("_MaskTex", props);
            _AOTex            = FindProperty("_AOTex", props);
            _EvoCube          = FindProperty("_EvoCube", props);
            
            _ShadowStrength   = FindProperty("_ShadowStrength", props);
            _AOScale          = FindProperty("_AOScale", props);
            
            //PBR
            _GGX              = FindProperty("_GGX", props);
            _Metallic         = FindProperty("_Metallic", props);
            _Roughness        = FindProperty("_Roughness", props);
            _Specular         = FindProperty("_Specular", props);
            _Sheen            = FindProperty("_Sheen", props);
            _Clearcoat        = FindProperty("_Clearcoat", props);
            _ClearcoatGloss   = FindProperty("_ClearcoatGloss", props);
            _Subsurface       = FindProperty("_Subsurface", props);
            _Anisotropic      = FindProperty("_Anisotropic", props);
            
            //SSS
            _NoiseTex          = FindProperty("_NoiseTex", props);
            _SSSLightDir       = FindProperty("_SSSLightDir", props);
            _ScatterNum        = FindProperty("_ScatterNum", props);
            _SSSColor          = FindProperty("_SSSColor", props);
            _ScatterPower      = FindProperty("_ScatterPower", props);
            _ScatterScale      = FindProperty("_ScatterScale", props);
            _ScatterRadius     = FindProperty("_ScatterRadius", props);
            _ScatterThickness  = FindProperty("_ScatterThickness", props);
            
            //Detail
            _DetailTex         = FindProperty("_DetailTex", props);
            _DetailThickness   = FindProperty("_DetailThickness", props);
            _DetailNormalMap   = FindProperty("_DetailNormalMap", props);
            _DetailBumpScale   = FindProperty("_DetailBumpScale", props);
            _DetailScale       = FindProperty("_DetailScale", props);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            base.OnGUI(materialEditor, properties);

            //isTrim = EditorGUILayout.Toggle("Color base", isTrim);
            //if (isTrim)
//            EditorGUILayout.LabelField("基本参数");
//            EditorGUI.indentLevel++;
//            {
                DrawSlider(_Brightness, "亮度",0, 2);
//                DrawSlider(_Saturation, "饱和度",0, 2);
//                DrawSlider(_Contrast, "对比度",0, 2);
//            }
//            EditorGUI.indentLevel--;
//            EditorGUILayout.Space();
            DrawSlider(_ShadowStrength,_ShadowStrength.displayName);
            // Texture
            materialEditor.TexturePropertySingleLine(new GUIContent(_MainTex.displayName), _MainTex, _Color);
            materialEditor.TexturePropertySingleLine(new GUIContent(_NormalMap.displayName), _NormalMap);
            if (_NormalMap.textureValue)
            {
                EditorGUI.indentLevel++;
                DrawSlider(_BumpScale,_BumpScale.displayName, 0, 2);
                EditorGUI.indentLevel--;
            }
            materialEditor.DefaultShaderProperty(_DetailNormalMap, _DetailNormalMap.displayName);
            if (_DetailNormalMap.textureValue)
            {
                EditorGUI.indentLevel++;
                DrawSlider(_DetailBumpScale, _DetailBumpScale.displayName, 0, 2);
                EditorGUI.indentLevel--;
            }
            materialEditor.TexturePropertySingleLine(new GUIContent(_MaskTex.displayName), _MaskTex);
            materialEditor.TexturePropertySingleLine(new GUIContent(_EvoCube.displayName), _EvoCube);
            materialEditor.TexturePropertySingleLine(new GUIContent(_AOTex.displayName), _AOTex);
            if (_AOTex.textureValue)
            {
                EditorGUI.indentLevel++;
                DrawSlider(_AOScale, _AOScale.displayName, 0, 1);
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.Space();
            materialEditor.ColorProperty(_SpecularTint, _SpecularTint.displayName);
            materialEditor.ColorProperty(_SheenTint, _SheenTint.displayName);
            EditorGUILayout.Space();
            // PBRMaterial
            PBRMaterial pbrMat = (PBRMaterial)_material.GetFloat("_Mat");
            _materialEditor.ShaderProperty(_PBRMat,_PBRMat.displayName);
            int index = (int) pbrMat;
            _materialEditor.ShaderProperty(_GGX,_GGX.displayName);
            DrawVector(_Metallic, index);
            DrawVector(_Roughness, index);
            DrawVector(_Specular, index);
            DrawVector(_Sheen, index);
            DrawVector(_Clearcoat, index);
            DrawVector(_ClearcoatGloss, index);
            DrawVector(_Subsurface, index);
            DrawVector(_Anisotropic, index);
            
            EditorGUILayout.Space();
            
            //isDetail = EditorGUILayout.Toggle("Detail", isDetail);
            materialEditor.TexturePropertySingleLine(new GUIContent(_DetailTex.displayName), _DetailTex);
            if (_DetailTex.textureValue)
            {
                EditorGUI.indentLevel++;
//                {

//                    DrawSlider(_DetailThickness, _DetailThickness.displayName);
                    //DrawSlider(_DetailBumpScale, _DetailBumpScale.displayName, 0, 10);
//                    DrawSlider(_DetailScale, _DetailScale.displayName, 0, 1);
//                }
                EditorGUI.indentLevel--;
            }

            //isDrawSSS = EditorGUILayout.Toggle("SSS", isDrawSSS);
            //_SSSEnable.floatValue = isDrawSSS ? 1 : 0;
            _materialEditor.ShaderProperty(_ScatterThickness,_ScatterThickness.displayName);
            if (pbrMat == PBRMaterial.Skin && _ScatterThickness.floatValue > 0)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent(_NoiseTex.displayName), _NoiseTex);
                materialEditor.TexturePropertySingleLine(new GUIContent(_ThicknessTex.displayName), _ThicknessTex);
                //_materialEditor.ShaderProperty(_SSSLightDir,_SSSLightDir.displayName);
                DrawAngle(_SSSLightDir);
                _materialEditor.ShaderProperty(_ScatterNum,_ScatterNum.displayName);
                _materialEditor.ShaderProperty(_SSSColor,_SSSColor.displayName);
                _materialEditor.ShaderProperty(_ScatterPower,_ScatterPower.displayName);
                _materialEditor.ShaderProperty(_ScatterScale,_ScatterScale.displayName);
                _materialEditor.ShaderProperty(_ScatterRadius,_ScatterRadius.displayName);
               
            }
            

        }

        protected void DrawSlider(MaterialProperty floatProp, string title, float min = 0, float max = 1)
        {
            //Debug.Log("set " + vecProp.name);
            float oldValue = floatProp.floatValue;
            float newValue = EditorGUILayout.Slider(title, oldValue, min, max);
            if (Math.Abs(newValue - oldValue) > 0f)
            {
                floatProp.floatValue = newValue;
            }
        }
        
        protected void DrawAngle(MaterialProperty vecProp)
        {
            //Debug.Log("set " + vecProp.name);
            Vector4 vec4 = vecProp.vectorValue;
            EditorGUILayout.LabelField(vecProp.displayName);
            EditorGUI.indentLevel++;
            float xValue = EditorGUILayout.Slider("x", vec4.x, -1f, 1);
            float yValue = EditorGUILayout.Slider("y", vec4.y, -1f, 1);
            float zValue = EditorGUILayout.Slider("z", vec4.z, -1f, 1);
            EditorGUI.indentLevel--;
            if (Math.Abs(xValue - vec4.x) > 0f || Math.Abs(yValue - vec4.y) > 0f || Math.Abs(zValue - vec4.z) > 0f)
            {
                vec4 = new Vector4(xValue, yValue, zValue, vec4.w);
                _material.SetVector(vecProp.name, vec4);
            }
        }
        
        protected void DrawVector(MaterialProperty vecProp, int index)
        {
            //Debug.Log("set " + vecProp.name);
            Vector4 vec4 = vecProp.vectorValue;
            float newValue = EditorGUILayout.Slider(vecProp.displayName, vec4[index], 0f, 1f);
            if (Math.Abs(newValue - vec4[index]) > 0f)
            {
                vec4[index] = newValue;
                _material.SetVector(vecProp.name, vec4);
            }
        }
    }
}