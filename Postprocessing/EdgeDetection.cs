#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Kacper119p.CelShading.PostProcessing
{
    /// <summary>
    /// Provides screen space edge detection.
    /// </summary>
    public sealed class EdgeDetection : ScriptableRendererFeature
    {
        [Tooltip("Color of edge lines.")]
        [SerializeField, ColorUsage(false, true)]
        private Color _edgeColor = new Color(0, 0, 0, 1);

        [Tooltip("Thickness of edge lines.")]
        [SerializeField] private float _thickness = 1f;

        [Tooltip("Threshold for detecting edges using depth buffer.")]
        [SerializeField] private float _depthThreshold = 1f;

        [Tooltip("Threshold for detecting edges using normal buffer.")]
        [SerializeField] private float _normalThreshold = 1f;

        [Tooltip("Should check for edges using scene color?")]
        [SerializeField] private bool _colorEdgeDetection;

        [Tooltip("Threshold for detecting edges using scene color.")]
        [SerializeField, Range(0.0f, 1.0f)] private float _colorThreshold;

        [SerializeField, HideInInspector] private Shader _shader;

        private EdgeDetectionRenderPass _renderPass;
        private static readonly int EdgeColorPropertyID = Shader.PropertyToID("_Edge_Color");
        private static readonly int ThicknessPropertyID = Shader.PropertyToID("_Sampling_Range");
        private static readonly int DepthThresholdPropertyID = Shader.PropertyToID("_Depth_Threshold");
        private static readonly int NormalThresholdPropertyID = Shader.PropertyToID("_Normal_Threshold");
        private static readonly int ColorThresholdPropertyID = Shader.PropertyToID("_Color_Threshold");
        private static LocalKeyword _colorEdgesKeyword;
        private const int CameraTypes = (int)CameraType.Game | (int)CameraType.SceneView;

        /// <summary>
        /// Color of edge lines.
        /// </summary>
        public Color EdgeColor
        {
            get => _edgeColor;
            set
            {
                _edgeColor = value;
                _renderPass.Material.SetColor(EdgeColorPropertyID, _edgeColor);
            }
        }

        /// <summary>
        /// Thickness of edge lines.
        /// </summary>
        public float Thickness
        {
            get => _thickness;
            set
            {
                _thickness = value;
                _renderPass.Material.SetFloat(ThicknessPropertyID, _thickness * 0.001f);
            }
        }

        /// <summary>
        /// Threshold for detecting edges using depth buffer.
        /// </summary>
        public float DepthThreshold
        {
            get => _depthThreshold;
            set
            {
                _depthThreshold = value;
                _renderPass.Material.SetFloat(DepthThresholdPropertyID, _depthThreshold * 0.05f);
            }
        }

        /// <summary>
        /// Threshold for detecting edges using normal buffer.
        /// </summary>
        public float NormalThreshold
        {
            get => _normalThreshold;
            set
            {
                _normalThreshold = value;
                _renderPass.Material.SetFloat(NormalThresholdPropertyID, _normalThreshold * 0.05f);
            }
        }

        /// <summary>
        /// Should check for edges using scene color?
        /// </summary>
        public bool ColorEdgeDetection
        {
            get => _colorEdgeDetection;
            set
            {
                _colorEdgeDetection = value;
                _renderPass.Material.SetKeyword(_colorEdgesKeyword, _colorEdgeDetection);
            }
        }

        /// <summary>
        /// Threshold for detecting edges using scene color.
        /// </summary>
        public float ColorThreshold
        {
            get => _colorThreshold;
            set
            {
                _colorThreshold = value;
                _renderPass.Material.SetFloat(ColorThresholdPropertyID, _colorThreshold);
            }
        }

        public override void Create()
        {
            if (_shader == null)
            {
                _shader = GetShader();
            }

            _colorEdgesKeyword = _shader.keywordSpace.FindKeyword("_COLOR_EDGES_ON");
            _renderPass = new EdgeDetectionRenderPass(_shader)
            {
                renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
            };
            SetMaterialProperties();
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer,
            in RenderingData renderingData)
        {
            _renderPass.ConfigureInput(ScriptableRenderPassInput.Color | ScriptableRenderPassInput.Depth |
                                       ScriptableRenderPassInput.Normal);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (((int)renderingData.cameraData.cameraType & CameraTypes) != 0)
                renderer.EnqueuePass(_renderPass);
        }

#if UNITY_EDITOR
        private void OnValidate()
        {
            SetMaterialProperties();
        }
#endif

        private static Shader GetShader()
        {
            Shader result = Shader.Find("Hidden/kacper119p/EdgeDetection");
            if (result == null)
            {
                throw new MissingReferenceException("Edge detection shader not found");
            }

            return result;
        }


        private void SetMaterialProperties()
        {
            if (_renderPass == null) return;
            _renderPass.Material.SetColor(EdgeColorPropertyID, _edgeColor);
            _renderPass.Material.SetFloat(ThicknessPropertyID, _thickness * 0.001f);
            _renderPass.Material.SetFloat(DepthThresholdPropertyID, _depthThreshold * 0.05f);
            _renderPass.Material.SetFloat(NormalThresholdPropertyID, _normalThreshold * 0.05f);
            _renderPass.Material.SetKeyword(_colorEdgesKeyword, _colorEdgeDetection);
            _renderPass.Material.SetFloat(ColorThresholdPropertyID, _colorThreshold);
        }

        private sealed class EdgeDetectionRenderPass : ScriptableRenderPass
        {
            private readonly Material _material;

            public Material Material => _material;

            public EdgeDetectionRenderPass(Shader shader)
            {
                _material = new Material(shader)
                {
                    hideFlags = HideFlags.HideAndDontSave
                };
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get();
                Blit(cmd, ref renderingData, _material);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public void Dispose()
            {
#if UNITY_EDITOR
                if (EditorApplication.isPlaying)
                {
                    Destroy(_material);
                }
                else
                {
                    DestroyImmediate(_material);
                }
#else
                Destroy(_material);
#endif
            }
        }
    }
}
