using System;
using UnityEngine;
using UnityEditor;

namespace com.kacper119p.CelShading.Editor.Utility
{
    /// <summary>
    /// Contains helper functions for convenient creation of custom Shader Editors.
    /// </summary>
    public static class ShaderEditorHelper
    {
        private static readonly Color BackgroundColor = new Color(0.85f, 0.85f, 0.85f, 1f);
        private const float SpaceHeight = 18;

        /// <summary>
        /// Used as more performant alternative to System.Ling for seeking properties by name in array.
        /// </summary>
        /// <param name="name">Name of sought property.</param>
        /// <param name="properties">Material properties.</param>
        /// <returns>Reference to Material Property with given name.</returns>
        /// <exception cref="MaterialPropertyNotFoundException"></exception>
        private static MaterialProperty SeekPropertyByName(this MaterialProperty[] properties, string name)
        {
            for (int i = 0; i < properties.Length; ++i)
            {
                if (properties[i].name.Equals(name))
                {
                    return properties[i];
                }
            }
            throw new MaterialPropertyNotFoundException($"Property \"{name}\" couldn't be found in given material");
        }

        /// <summary>
        /// Displays and handles changes of generic property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="displayName">Custom display name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void ShaderProperty(string name,
            string displayName,
            MaterialEditor materialEditor,
            MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            materialEditor.ShaderProperty(property, displayName);
        }

        /// <summary>
        /// Displays and handles changes of generic property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void ShaderProperty(string name, MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            materialEditor.ShaderProperty(property, property.displayName);
        }

        /// <summary>
        /// Displays and handles changes of float property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void FloatProperty(string name, MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            materialEditor.FloatProperty(property, property.displayName);
        }

        /// <summary>
        /// Displays and handles changes of float property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="displayName">Custom display name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void FloatProperty(string name,
            string displayName,
            MaterialEditor materialEditor,
            MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            materialEditor.FloatProperty(property, displayName);
        }

        /// <summary>
        /// Displays and handles changes of float property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="displayName">Custom display name.</param>
        /// <param name="range">Maximum and minimum value for float property.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void FloatProperty(string name,
            string displayName,
            Vector2 range,
            MaterialEditor materialEditor,
            MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            float value = materialEditor.FloatProperty(property, displayName);
            property.floatValue = Mathf.Clamp(value, range.x, range.y);
        }

        /// <summary>
        /// Displays and handles changes of float property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="range">Maximum and minimum value for float property.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void FloatProperty(string name,
            Vector2 range,
            MaterialEditor materialEditor,
            MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            float value = materialEditor.FloatProperty(property, property.displayName);
            property.floatValue = Mathf.Clamp(value, range.x, range.y);
        }

        /// <summary>
        /// Displays and handles changes of 2d vector property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="displayName">Custom display name.</param>
        /// <param name="properties">Material properties array.</param>
        public static void Vector2Property(string name, string displayName, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty property = properties.SeekPropertyByName(name);
            Vector2 value = EditorGUILayout.Vector2Field(displayName, property.vectorValue);
            if (EditorGUI.EndChangeCheck())
            {
                property.vectorValue = value;
            }
        }

        /// <summary>
        /// Displays and handles changes of 2d vector property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="properties">Material properties array.</param>
        public static void Vector2Property(string name, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty property = properties.SeekPropertyByName(name);
            Vector2 value = EditorGUILayout.Vector2Field(property.displayName, property.vectorValue);
            if (EditorGUI.EndChangeCheck())
            {
                property.vectorValue = value;
            }
        }

        /// <summary>
        /// Displays and handles changes of 3d vector property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="displayName">Custom display name.</param>
        /// <param name="properties">Material properties array.</param>
        public static void Vector3Property(string name, string displayName, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty property = properties.SeekPropertyByName(name);
            Vector3 value = EditorGUILayout.Vector3Field(displayName, property.vectorValue);
            if (EditorGUI.EndChangeCheck())
            {
                property.vectorValue = value;
            }
        }

        /// <summary>
        /// Displays and handles changes of 3d vector property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="properties">Material properties array.</param>
        public static void Vector3Property(string name, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty property = properties.SeekPropertyByName(name);
            Vector3 value = EditorGUILayout.Vector3Field(property.displayName, property.vectorValue);
            if (EditorGUI.EndChangeCheck())
            {
                property.vectorValue = value;
            }
        }

        /// <summary>
        /// Displays and handles changes of 4d vector property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// /// <param name="displayName">Custom display name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void Vector4Property(string name,
            string displayName,
            MaterialEditor materialEditor,
            MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            materialEditor.FloatProperty(property, displayName);
        }

        /// <summary>
        /// Displays and handles changes of 4d vector property in editor.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        /// <param name="properties">Material properties array.</param>
        public static void Vector4Property(string name, MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            MaterialProperty property = properties.SeekPropertyByName(name);
            materialEditor.VectorProperty(property, property.displayName);
        }

        /// <summary>
        /// Displays and activates or activates shader keyword according to user input.<br/>
        /// Uses toggle field as UI.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        public static bool ToggleShaderKeywordProperty(string name,
            MaterialEditor materialEditor)
            => ToggleShaderKeywordProperty(name, name, materialEditor);

        /// <summary>
        /// Displays and activates or activates shader keyword according to user input.<br/>
        /// Uses toggle field as UI.
        /// </summary>
        /// <param name="name">Property reference name.</param>
        /// <param name="displayName">Custom display name.</param>
        /// <param name="materialEditor">Current Material Editor.</param>
        public static bool ToggleShaderKeywordProperty(string name,
            string displayName,
            MaterialEditor materialEditor)
        {
            Material targetMaterial = (Material)materialEditor.target;

            bool value = Array.IndexOf(targetMaterial.shaderKeywords, name) != -1;

            EditorGUI.BeginChangeCheck();
            value = EditorGUILayout.Toggle(displayName, value);
            if (EditorGUI.EndChangeCheck())
            {
                if (value)
                {
                    targetMaterial.EnableKeyword(name);
                }
                else
                {
                    targetMaterial.DisableKeyword(name);
                }
            }

            return value;
        }

        /// <summary>
        /// Begins foldout section.
        /// </summary>
        /// <param name="foldout">true - unfolded, false - folded</param>
        /// <param name="title">Title.</param>
        /// <returns>State of fold after checking for user input.</returns>
        public static bool BeginFoldout(bool foldout, string title)
        {
            GUI.backgroundColor = BackgroundColor;
            foldout = EditorGUILayout.BeginFoldoutHeaderGroup(foldout, title, EditorStyles.foldoutHeader);
            GUI.backgroundColor = Color.white;
            return foldout;
        }

        /// <summary>
        /// Ends current foldout section.
        /// </summary>
        /// <param name="foldout"></param>
        public static void EndFoldout(bool foldout)
        {
            EditorGUILayout.EndFoldoutHeaderGroup();
            if (foldout)
            {
                EditorGUILayout.Space(SpaceHeight);
            }
        }

        /// <summary>
        /// Puts vertical space at current position.
        /// </summary>
        public static void Space()
        {
            EditorGUILayout.Space(SpaceHeight);
        }
    }
}
