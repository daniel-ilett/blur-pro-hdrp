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
	TEXTURE2D_X(_InputTexture);
	uint _KernelSize;
	float _Spread;

	static const float E = 2.71828f;

	float gaussian(int x, int y)
	{
		float sigmaSqu = _Spread * _Spread;
		return (1 / sqrt(TWO_PI * sigmaSqu)) * pow(E, -((x * x) + (y * y)) / (2 * sigmaSqu));
	}

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        uint2 positionSS = input.texcoord * _ScreenSize.xy;

		float3 col = float3(0.0f, 0.0f, 0.0f);
		float kernelSum = 0.0f;

		int upper = ((_KernelSize - 1) / 2);
		int lower = -upper;

		float2 uv;

		for (int x = lower; x <= upper; ++x)
		{
			for (int y = lower; y <= upper; ++y)
			{
				float gauss = gaussian(x, y);
				kernelSum += gauss;
				uv = positionSS + int2(x, y);
				col += gauss * LOAD_TEXTURE2D_X(_InputTexture, uv).xyz;
			}
		}

		col /= kernelSum;

		return float4(col, 1.0f);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "Blur"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }
    Fallback Off
}
