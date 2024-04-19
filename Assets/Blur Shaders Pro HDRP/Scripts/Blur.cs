namespace BlurShadersPro.HDRP
{
    using UnityEngine;
    using UnityEngine.Rendering;
    using UnityEngine.Rendering.HighDefinition;
    using System;

    [Serializable, VolumeComponentMenu("Post-processing/Blur Shaders Pro (HDRP)/Blur")]
    public sealed class Blur : CustomPostProcessVolumeComponent, IPostProcessComponent
    {
        [Tooltip("Blur Strength")]
        public ClampedIntParameter strength = new ClampedIntParameter(1, 1, 37);

        Material m_Material;

        public bool IsActive() => m_Material != null && strength.value > 1;

        // Remember to add this post process in the Custom Post Process Orders list 
        // (Project Settings > HDRP Default Settings).
        public override CustomPostProcessInjectionPoint injectionPoint =>
            CustomPostProcessInjectionPoint.AfterPostProcess;

        const string kShaderName = "BlurShadersProHDRP/Blur";

        public override void Setup()
        {
            if (Shader.Find(kShaderName) != null)
            {
                m_Material = new Material(Shader.Find(kShaderName));
            }
            else
            {
                Debug.LogError($"Unable to find shader '{kShaderName}' for the Blur effect.");
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

            m_Material.SetTexture("_InputTexture", source);

            HDUtils.DrawFullScreen(cmd, m_Material, destination);
        }

        public override void Cleanup()
        {
            CoreUtils.Destroy(m_Material);
        }
    }
}
