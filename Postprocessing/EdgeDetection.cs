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

        private EdgeDetectionRenderPass _renderPass;
        private static readonly int ThicknessPropertyID = Shader.PropertyToID("_Sampling_Range");
        private static readonly int DepthThresholdPropertyID = Shader.PropertyToID("_Depth_Threshold");
        private static readonly int NormalThresholdPropertyID = Shader.PropertyToID("_Normal_Threshold");
        private static readonly int EdgeColorPropertyID = Shader.PropertyToID("_Edge_Color");
        private const int CameraTypes = (int)CameraType.Game | (int)CameraType.SceneView;

        public override void Create()
        {
            _renderPass = new EdgeDetectionRenderPass
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

        private void SetMaterialProperties()
        {
            if (_renderPass == null) return;
            _renderPass.Material.SetFloat(ThicknessPropertyID, _thickness * 0.001f);
            _renderPass.Material.SetFloat(DepthThresholdPropertyID, _depthThreshold * 0.05f);
            _renderPass.Material.SetFloat(NormalThresholdPropertyID, _normalThreshold * 0.05f);
            _renderPass.Material.SetColor(EdgeColorPropertyID, _edgeColor);
        }

        private sealed class EdgeDetectionRenderPass : ScriptableRenderPass
        {
            private readonly Material _material;

            public Material Material => _material;

            public EdgeDetectionRenderPass()
            {
                Shader shader = Shader.Find("Hidden/kacper119p/EdgeDetection");
                if (shader == null)
                {
                    throw new MissingReferenceException("Edge detection shader not found");
                }

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
