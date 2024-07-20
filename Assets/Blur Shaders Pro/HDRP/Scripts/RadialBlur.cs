namespace BlurShadersPro.HDRP
{
    using UnityEngine;
    using UnityEngine.Rendering;
    using UnityEngine.Rendering.HighDefinition;
    using System;

    [Serializable, VolumeComponentMenu("Post-processing/Blur Shaders Pro (HDRP)/RadialBlur")]
    public sealed class RadialBlur : CustomPostProcessVolumeComponent, IPostProcessComponent
    {
        [Tooltip("Blur Strength. Higher values require more system resources.")]
        public ClampedIntParameter strength = new ClampedIntParameter(1, 1, 500);

        [Tooltip("Distance between samples. Larger values may result in artefacts.")]
        public ClampedIntParameter stepSize = new ClampedIntParameter(5, 1, 20);

        Material m_Material;

        public bool IsActive() => m_Material != null && strength.value > 1;

        // Remember to add this post process in the Custom Post Process Orders list 
        // (Project Settings > HDRP Default Settings).
        public override CustomPostProcessInjectionPoint injectionPoint =>
            CustomPostProcessInjectionPoint.AfterPostProcess;

        const string kShaderName = "BlurShadersProHDRP/RadialBlur";

        public override void Setup()
        {
            if (Shader.Find(kShaderName) != null)
            {
                m_Material = new Material(Shader.Find(kShaderName));
            }
            else
            {
                Debug.LogError($"Unable to find shader '{kShaderName}' for the RadialBlur effect.");
            }
        }

        public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
        {
            if (m_Material == null)
            {
                return;
            }

            m_Material.SetInt("_KernelSize", strength.value);
            m_Material.SetFloat("_Spread", strength.value / 7.5f);
            m_Material.SetFloat("_StepSize", stepSize.value / 1000.0f);

            m_Material.SetTexture("_InputTexture", source);

            HDUtils.DrawFullScreen(cmd, m_Material, destination);
        }

        public override void Cleanup()
        {
            CoreUtils.Destroy(m_Material);
        }
    }
}
