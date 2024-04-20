namespace BlurShadersPro.HDRP
{
    using UnityEngine;
    using UnityEngine.Rendering;
    using UnityEngine.Rendering.HighDefinition;
    using GraphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat;
    using System;
    using System.Collections.Generic;

    [Serializable, VolumeComponentMenu("Post-processing/Blur Shaders Pro (HDRP)/Blur")]
    public sealed class Blur : CustomPostProcessVolumeComponent, IPostProcessComponent
    {
        [Tooltip("Blur Strength")]
        public ClampedIntParameter strength = new ClampedIntParameter(1, 1, 500);

        private RTHandle blurTexHandle = null;

        Material m_Material;

        public bool IsActive() => m_Material != null && strength.value > 1;

        // Remember to add this post process in the Custom Post Process Orders list 
        // (Project Settings > HDRP Default Settings).
        public override CustomPostProcessInjectionPoint injectionPoint =>
            CustomPostProcessInjectionPoint.AfterPostProcess;

        const string kShaderName = "BlurShadersProHDRP/Blur";

        // With much help from https://github.com/keijiro/Kino/tree/master/Packages/jp.keijiro.kino.post-processing
        // for assistance in getting the two-pass version of this blur effect working.
        private RTHandle GetBlurTexture(HDCamera camera)
        {
            if(blurTexHandle == null)
            {
                Allocate(camera);
            }

            return blurTexHandle;
        }

        private void Allocate(HDCamera camera)
        {
            var width = camera.actualWidth;
            var height = camera.actualHeight;

            const GraphicsFormat rtFormat = GraphicsFormat.R16G16B16A16_SFloat;
            blurTexHandle = RTHandles.Alloc(width, height, colorFormat: rtFormat);
        }

        private void ReleaseTextures()
        {
            RTHandles.Release(blurTexHandle);
        }

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

            var blurTexHandle = GetBlurTexture(camera);

            m_Material.SetInt("_KernelSize", strength.value);
            m_Material.SetFloat("_Spread", strength.value / 7.5f);

            m_Material.SetTexture("_SourceTexture", source);
            HDUtils.DrawFullScreen(cmd, m_Material, blurTexHandle, shaderPassId: 0);

            m_Material.SetTexture("_InputTexture", blurTexHandle);
            HDUtils.DrawFullScreen(cmd, m_Material, destination, shaderPassId: 1);
        }

        public override void Cleanup()
        {
            ReleaseTextures();
            CoreUtils.Destroy(m_Material);
        }
    }
}
