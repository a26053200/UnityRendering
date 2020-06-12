using UnityEditor;
using UnityEngine;

namespace DisneyPBR
{
    public class BaseShaderGUI : ShaderGUI
    {
        protected Material _material;
        protected MaterialEditor _materialEditor;
        protected MaterialProperty _MainTex;
        protected MaterialProperty _Color;
        
        protected virtual void FindProperties(MaterialProperty[] props)
        {
            _MainTex = FindProperty("_MainTex", props);
            _Color = FindProperty("_Color", props);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            //base.OnGUI(materialEditor, properties);
            FindProperties(properties);
            _materialEditor = materialEditor;
            _material = _materialEditor.target as Material; 
        }
    }
}