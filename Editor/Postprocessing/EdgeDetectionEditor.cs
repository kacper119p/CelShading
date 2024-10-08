using Kacper119p.CelShading.PostProcessing;
using UnityEditor;

namespace com.kacper119p.CelShading.Editor.Postprocessing
{
    [CustomEditor(typeof(EdgeDetection))]
    internal class EdgeDetectionEditor : UnityEditor.Editor
    {
        private SerializedProperty _edgeColor;
        private SerializedProperty _thickness;
        private SerializedProperty _depthThreshold;
        private SerializedProperty _normalThreshold;
        private SerializedProperty _colorEdgeDetection;
        private SerializedProperty _colorThreshold;
        private SerializedProperty _renderPassEvent;

        private void OnEnable()
        {
            _edgeColor = serializedObject.FindProperty("_edgeColor");
            _thickness = serializedObject.FindProperty("_thickness");
            _depthThreshold = serializedObject.FindProperty("_depthThreshold");
            _normalThreshold = serializedObject.FindProperty("_normalThreshold");
            _colorEdgeDetection = serializedObject.FindProperty("_colorEdgeDetection");
            _colorThreshold = serializedObject.FindProperty("_colorThreshold");
            _renderPassEvent = serializedObject.FindProperty("_renderPassEvent");
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();
            EditorGUILayout.PropertyField(_edgeColor);
            EditorGUILayout.PropertyField(_thickness);
            EditorGUILayout.PropertyField(_depthThreshold);
            EditorGUILayout.PropertyField(_normalThreshold);
            EditorGUILayout.PropertyField(_colorEdgeDetection);
            if (_colorEdgeDetection.boolValue)
            {
                EditorGUI.indentLevel++;
                EditorGUILayout.PropertyField(_colorThreshold);
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.PropertyField(_renderPassEvent);
            serializedObject.ApplyModifiedProperties();
        }
    }
}
