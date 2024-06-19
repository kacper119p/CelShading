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
        [SerializeField, ColorUsage(false, true)]
        private Color _edgeColor = new Color(0, 0, 0, 1);

        [SerializeField] private float _thickness = 1f;
        [SerializeField] private float _depthThreshold = 1f;
        [SerializeField] private float _normalThreshold = 1f;

        [SerializeField] private bool _colorEdgeDetection;
        [SerializeField, Range(0.0f, 1.0f)]private float _colorThreshold;
        
        [SerializeField, HideInInspector] private Shader _shader;

        private EdgeDetectionRenderPass _renderPass;
        private static readonly int EdgeColorPropertyID = Shader.PropertyToID("_Edge_Color");
        private static readonly int ThicknessPropertyID = Shader.PropertyToID("_Sampling_Range");
        private static readonly int DepthThresholdPropertyID = Shader.PropertyToID("_Depth_Threshold");
        private static readonly int NormalThresholdPropertyID = Shader.PropertyToID("_Normal_Threshold");
        private static readonly int ColorThresholdPropertyID = Shader.PropertyToID("_Color_Threshold");
        private static LocalKeyword _colorEdgesKeyword;
        private const int CameraTypes = (int)CameraType.Game | (int)CameraType.SceneView;

        public Color EdgeColor
        {
            get => _edgeColor;
            set
            {
                _edgeColor = value;
                _renderPass.Material.SetColor(EdgeColorPropertyID, _edgeColor);
            }
        }

        public float Thickness
        {
            get => _thickness;
            set
            {
                _thickness = value;
                _renderPass.Material.SetFloat(ThicknessPropertyID, _thickness * 0.001f);
            }
        }

        public float DepthThreshold
        {
            get => _depthThreshold;
            set
            {
                _depthThreshold = value;
                _renderPass.Material.SetFloat(DepthThresholdPropertyID, _depthThreshold * 0.05f);
            }
        }

        public float NormalThreshold
        {
            get => _normalThreshold;
            set
            {
                _normalThreshold = value;
                _renderPass.Material.SetFloat(NormalThresholdPropertyID, _normalThreshold * 0.05f);
            }
        }

        public bool ColorEdgeDetection
        {
            get => _colorEdgeDetection;
            set
            {
                _colorEdgeDetection = value;
                _renderPass.Material.SetKeyword(_colorEdgesKeyword, _colorEdgeDetection);
            }
        }
        
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
                _material = new Material(shader);
            }

            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
            }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get();
                Blit(cmd, ref renderingData, _material, 0);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public override void OnCameraCleanup(CommandBuffer cmd)
            {
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
