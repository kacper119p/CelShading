using com.kacper119p.CelShading.Editor.Utility;
using UnityEditor;

namespace com.kacper119p.CelShading.Editor
{
    public class TriplanarCelShadingEditor : ShaderGUI
    {
        private static bool _triplanarOptionsFoldout = true;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            CelShadingEditorsCommon.DrawSurfaceInputs(materialEditor, properties);
            DrawTriplanarOptions(materialEditor, properties);
            CelShadingEditorsCommon.DrawMaterialOptions(materialEditor, properties);
        }

        private static void DrawTriplanarOptions(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            _triplanarOptionsFoldout =
                ShaderEditorHelper.BeginFoldout(_triplanarOptionsFoldout, "Triplanar mapping options");
            if (_triplanarOptionsFoldout)
            {
                ShaderEditorHelper.ShaderProperty("_Sampling_Space", materialEditor, properties);
                ShaderEditorHelper.ShaderProperty("_BlendOffset", materialEditor, properties);
                ShaderEditorHelper.ShaderProperty("_BlendPower", materialEditor, properties);
            }
            ShaderEditorHelper.EndFoldout(_triplanarOptionsFoldout);
        }
    }
}
