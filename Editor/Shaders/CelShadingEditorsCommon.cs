using com.kacper119p.CelShading.Editor.Utility;
using UnityEditor;

namespace com.kacper119p.CelShading.Editor
{
    public static class CelShadingEditorsCommon
    {
        private static bool _surfaceInputsFoldout = true;
        private static bool _materialOptionsFoldout = true;

        public static void DrawSurfaceInputs(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            _surfaceInputsFoldout = ShaderEditorHelper.BeginFoldout(_surfaceInputsFoldout, "Surface Inputs");
            if (_surfaceInputsFoldout)
            {
                ShaderEditorHelper.ShaderProperty("_BaseColor", materialEditor, properties);
                ShaderEditorHelper.ShaderProperty("_BaseMap", materialEditor, properties);
                ShaderEditorHelper.Space();

                ShaderEditorHelper.ShaderProperty("_EmissionColor", materialEditor, properties);
                ShaderEditorHelper.ShaderProperty("_EmissionMap", materialEditor, properties);
                ShaderEditorHelper.Space();

                ShaderEditorHelper.ShaderProperty("_NormalMap", materialEditor, properties);
                ShaderEditorHelper.ShaderProperty("_NormalStrength", materialEditor, properties);
                ShaderEditorHelper.Space();

                ShaderEditorHelper.ShaderProperty("_Specular", materialEditor, properties);
                ShaderEditorHelper.ShaderProperty("_SpecularMap", materialEditor, properties);
                ShaderEditorHelper.Space();

                bool rimHighlights = ShaderEditorHelper.ToggleShaderKeywordProperty(
                "_RIM_HIGHLIGHTS_ON",
                "Rim Highlights",
                materialEditor);

                if (rimHighlights)
                {
                    EditorGUI.indentLevel++;
                    ShaderEditorHelper.ShaderProperty("_RimHighlightsColor", materialEditor, properties);
                    ShaderEditorHelper.ShaderProperty("_RimHighlightsPower", materialEditor, properties);
                    EditorGUI.indentLevel--;
                }
            }
            ShaderEditorHelper.EndFoldout(_surfaceInputsFoldout);
        }

        public static void DrawMaterialOptions(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            _materialOptionsFoldout = ShaderEditorHelper.BeginFoldout(_materialOptionsFoldout, "Material options");
            if (_materialOptionsFoldout)
            {
                ShaderEditorHelper.ShaderProperty("_Additional_Lights", materialEditor, properties);
                ShaderEditorHelper.ShaderProperty("_Cull", materialEditor, properties);
                ShaderEditorHelper.Space();

                materialEditor.RenderQueueField();
                materialEditor.EnableInstancingField();
                materialEditor.DoubleSidedGIField();
            }
            ShaderEditorHelper.EndFoldout(_materialOptionsFoldout);
        }
    }
}
