using Kacper119p.CelShading.PostProcessing;
using UnityEditor;

namespace com.kacper119p.CelShading.Editor
{
    [CustomEditor(typeof(EdgeDetection))]
    public class EdgeDetectionEditor : UnityEditor.Editor
    {
        private SerializedProperty _edgeColor;
        private SerializedProperty _thickness;
        private SerializedProperty _depthThreshold;
        private SerializedProperty _normalThreshold;

        void OnEnable()
        {
            _edgeColor = serializedObject.FindProperty("_edgeColor");
            _thickness = serializedObject.FindProperty("_thickness");
            _depthThreshold = serializedObject.FindProperty("_depthThreshold");
            _normalThreshold = serializedObject.FindProperty("_normalThreshold");
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();
            EditorGUILayout.PropertyField(_edgeColor);
            EditorGUILayout.PropertyField(_thickness);
            EditorGUILayout.PropertyField(_depthThreshold);
            EditorGUILayout.PropertyField(_normalThreshold);
            serializedObject.ApplyModifiedProperties();
        }
    }
}
