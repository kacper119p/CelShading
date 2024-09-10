﻿using UnityEditor;

namespace com.kacper119p.CelShading.Editor
{
    public class CelShadingEditor : ShaderGUI
    {
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            CelShadingEditorsCommon.DrawSurfaceInputs(materialEditor, properties);
            CelShadingEditorsCommon.DrawMaterialOptions(materialEditor, properties);
        }
    }
}
