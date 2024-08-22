Shader "BlurShadersProHDRP/Blur"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    Varyings Vert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
        return output;
    }

    // List of properties to control your post process effect
	TEXTURE2D_X(_SourceTexture);
	TEXTURE2D(_InputTexture);
	float4 _InputTexture_TexelSize;
	uint _KernelSize;
	float _Spread;
	uint _BlurStepSize;

	static const float E = 2.71828f;

	float gaussian(int x)
	{
		float sigmaSqu = _Spread * _Spread;
		return (1 / sqrt(TWO_PI * sigmaSqu)) * pow(E, -(x * x) / (2 * sigmaSqu));
	}

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "HorizontalGaussian"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment FragHorizontal
                #pragma vertex Vert

				float4 FragHorizontal(Varyings input) : SV_Target
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

					uint2 positionSS = input.texcoord * _ScreenSize.xy;

					//return LOAD_TEXTURE2D_X(_SourceTexture, positionSS);

					float3 col = float3(0.0f, 0.0f, 0.0f);
					float kernelSum = 0.0f;

					int upper = ((_KernelSize - 1) / 2);
					int lower = -upper;

					float2 uv;

					for (int x = lower; x <= upper; x += _BlurStepSize)
					{
						float gauss = gaussian(x);
						kernelSum += gauss;
						uv = positionSS + int2(x, 0);
						col += gauss * LOAD_TEXTURE2D_X(_SourceTexture, uv).rgb;
					}

					col /= kernelSum;

					return float4(col, 1.0f);
				}
            ENDHLSL
        }

		Pass
        {
            Name "VerticalGaussian"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment FragVertical
                #pragma vertex Vert

				float4 FragVertical(Varyings input) : SV_Target
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

					float3 col = float3(0.0f, 0.0f, 0.0f);
					float kernelSum = 0.0f;

					int upper = ((_KernelSize - 1) / 2);
					int lower = -upper;

					float2 uv;

					for (int y = lower; y <= upper; y += _BlurStepSize)
					{
						float gauss = gaussian(y);
						kernelSum += gauss;
						uv = input.texcoord + float2(0, _InputTexture_TexelSize.y * y);
						col += gauss * SAMPLE_TEXTURE2D(_InputTexture, s_linear_clamp_sampler, uv).rgb;
					}

					col /= kernelSum;

					return float4(col, 1.0f);
				}
            ENDHLSL
        }

		Pass
        {
            Name "HorizontalBox"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment FragHorizontal
                #pragma vertex Vert

				float4 FragHorizontal(Varyings input) : SV_Target
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

					uint2 positionSS = input.texcoord * _ScreenSize.xy;

					//return LOAD_TEXTURE2D_X(_SourceTexture, positionSS);

					float3 col = float3(0.0f, 0.0f, 0.0f);
					float kernelSum = 0.0f;

					int upper = ((_KernelSize - 1) / 2);
					int lower = -upper;

					float2 uv;

					for (int x = lower; x <= upper; x += _BlurStepSize)
					{
						kernelSum++;
						uv = positionSS + int2(x, 0);
						col += LOAD_TEXTURE2D_X(_SourceTexture, uv).rgb;
					}

					col /= kernelSum;

					return float4(col, 1.0f);
				}
            ENDHLSL
        }

		Pass
        {
            Name "VerticalBox"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment FragVertical
                #pragma vertex Vert

				float4 FragVertical(Varyings input) : SV_Target
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

					float3 col = float3(0.0f, 0.0f, 0.0f);
					float kernelSum = 0.0f;

					int upper = ((_KernelSize - 1) / 2);
					int lower = -upper;

					float2 uv;

					for (int y = lower; y <= upper; y += _BlurStepSize)
					{
						kernelSum++;
						uv = input.texcoord + float2(0, _InputTexture_TexelSize.y * y);
						col += SAMPLE_TEXTURE2D(_InputTexture, s_linear_clamp_sampler, uv).rgb;
					}

					col /= kernelSum;

					return float4(col, 1.0f);
				}
            ENDHLSL
        }
    }
    Fallback Off
}
