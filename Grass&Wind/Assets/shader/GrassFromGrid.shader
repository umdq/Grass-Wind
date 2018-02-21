Shader "Unlit/GrassFromGridGS"
{
	Properties
	{
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_AlphaTex("Alpha (A)", 2D) = "white" {}
		_NoiseTex("Noise",2D) = "white" {}
		_WindTex("Wind",2D) = "white" {}
		_Length("Grass Length",float)=3
		_Width("Grass Width",range(0, 0.1)) = 0.05
		_Gravity("Grass Gravity",float)=0.34
		_Density("Grass Density",int)=3
		_DirectionIntensity("Random Direction Intensity",float)=0.19
		_LengthIntensity("Random Length Intensity",float)=0.1
		_OrientationIntensity("Random Orientation Intensity",float)=0.5
		_NoiseSampleScale("Noise Sample Scale",float)=0.5
		_NoiseSampleBias("Noise Sample Bias",float)=0.37

		_WindFrequency("Wind Frequency",float)=0.1
		_WindMin("Min Wind Force",float)=0.01
		_WindMax("Max Wind Force",float)=0.1
		_WindSampleScale("Wind sample scale",float)=1
		_WindSpeedX("Wind Speed X",float)=0.5
		_WindSpeedY("Wind Speed Y",float)=0.2

		//_OffsetDir("Root Offset Direction",Vector)=(1,0,-1,0)
		//_OffsetMax("Root Offset Max",float)=0.05
	}

	SubShader
	{
			Tags{ "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True" }
			//不用alpha blend，改用alpha test


		Pass
		{
			Cull Off
			//ZTest Always
			//ZWrite Off
			Tags{ "LightMode" = "ForwardBase" }
			AlphaToMask On

			CGPROGRAM
			#pragma vertex VS
			#pragma fragment PS
			#pragma hull HS
    		#pragma domain DS
			#pragma geometry GS

			#pragma target 5.0
			
			#include "UnityCG.cginc"

			#define NUM_STEP 15

			sampler2D _MainTex;
			sampler2D _AlphaTex;
			float _Length;
			float _Width;//严格来讲是half_width
			float _Gravity;
			int _Density;

			//Randomization
			sampler2D _NoiseTex;
			//float2 _NoiseSampleScale;
			//float2 _NoiseSampleBias;
			float _NoiseSampleScale;
			float _NoiseSampleBias;
			float _DirectionIntensity;
			float _LengthIntensity;
			float _OrientationIntensity;

			//wind
			sampler2D _WindTex;
			float _WindFrequency;
			float _WindMin;
			float _WindMax;
			float _WindSampleScale;
			float _WindSpeedX;
			float _WindSpeedY;

			//为了去除TS方案带来的分割线现象,与原mesh三角形斜边垂直——》结果没卵用。。。
			//float3 _OffsetDir=float3(1,0,-1);
			//unity规定只能在Properties中初始化，不然cpu中set
			//float4 _OffsetDir;
			//TS后两个triangle的中心距离，粗糙成：原step长/tess/2
			//float _OffsetMax;

			struct v2h
			{
				float4 posW: POSITION;
				float4 normalW: NORMAL;
				float2 terrainUV :TEXCOORD0;
			};

			struct PatchTess//for lod
    		{
       			float edgeTess[3]    : SV_TessFactor;
        		float insideTess : SV_InsideTessFactor;
    		};
     
    		struct h2d
    		{
        		float4 posW   : POSITION;
        		float4 normalW :NORMAL;
        		float2 terrainUV :TEXCOORD0;
    		};
     
    		struct d2g
    		{
        		float4 posW   : POSITION;
        		float4 normalW :NORMAL;
        		float2 terrainUV :TEXCOORD0;
    		};

			struct g2f
			{
				float4 posH: SV_POSITION;
				float4 normalW : NORMAL;
				float2 uv : TEXCOORD0;
			};

			v2h VS(appdata_base v)
			{
				v2h o;
				o.posW=mul(unity_ObjectToWorld,v.vertex);
				o.normalW=mul(unity_ObjectToWorld,v.normal);
				o.terrainUV=v.texcoord;
				return o;
			}
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     
    		

			PatchTess HSConstant( InputPatch<v2h, 3> patch,uint patchID :SV_PrimitiveID )
    		{
        		PatchTess pt = (PatchTess)0;
        		pt.edgeTess[0] = pt.edgeTess[1] = pt.edgeTess[2] =_Density;
        		pt.insideTess =_Density;    
        		return pt;
    		}

    		[domain("tri")]
    		[partitioning("integer")]
    		[outputtopology("triangle_cw")]
    		[patchconstantfunc("HSConstant")]
    		[outputcontrolpoints(3)]
    		[maxtessfactor(64.0f)]
    		//一般来说都是走个过场
    		h2d HS( InputPatch<v2h, 3> patch, uint cpID : SV_OutputControlPointID,uint patchID :SV_PrimitiveID )
    		{
        		h2d hout= (h2d)0;
        		hout.posW = patch[cpID].posW;
        		hout.normalW = patch[cpID].normalW;
        		hout.terrainUV=patch[cpID].terrainUV;
        		return hout;
    		}
    
    		[domain("tri")]
    		d2g DS( PatchTess HSConstantData, 
    					const OutputPatch<h2d, 3> patch, 
    					float3 BarycentricCoords : SV_DomainLocation)
    		{
        		d2g dout = (d2g)0;
     
        		float u = BarycentricCoords.x;
        		float v = BarycentricCoords.y;
        		float w = BarycentricCoords.z;

        		//暂且不sample height map，只是单纯的平面插值，反正需要的也只是更密集
        		dout.posW = patch[0].posW * u + patch[1].posW * v + patch[2].posW * w;
        		dout.normalW = patch[0].normalW * u + patch[1].normalW * v + patch[2].normalW * w;
          		dout.terrainUV = patch[0].terrainUV * u + patch[1].terrainUV * v + patch[2].terrainUV * w;
        		return dout;
    		}

			///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			g2f ConstructorG2f(float4 posH,float4 normalW,float2 uv)//严格来说在这里的作用是复制构造函数
			{
				g2f output;
				output.posH=posH;
				output.normalW=normalW;
				output.uv=uv;
				return output;
			}

			[maxvertexcount( (NUM_STEP+1)*2 )]
			void GS(triangle d2g i[3], inout TriangleStream<g2f> triStream)
			{
				float4 root=(i[0].posW+i[1].posW+i[2].posW)/3.0f;
				float4 stalkDir=normalize((i[0].normalW+i[1].normalW+i[2].normalW)/3.0f);
				float4 tangentW=normalize(float4( (i[1].posW-i[0].posW).xyz ,0.0f));//for width，也决定orientation

				//fixed randomization
				float2 rootTerrainUV=(i[0].terrainUV+i[1].terrainUV+i[2].terrainUV)/3.0f;
				//float r=tex2Dlod(_NoiseTex, float4(rootTerrainUV * _NoiseSampleScale + float2(0,0.111), 0, 0)).r;
				//float g=tex2Dlod(_NoiseTex, float4(rootTerrainUV * _NoiseSampleScale + float2(0.253,0.679), 0, 0)).r;
				//float b=tex2Dlod(_NoiseTex, float4(rootTerrainUV * _NoiseSampleScale + float2(0.333,0.238), 0, 0)).r;
				//float3 noiseNormal=float3(r,g,b)*2-1;
				float3 noiseNormal=tex2Dlod(_NoiseTex, float4(rootTerrainUV * _NoiseSampleScale + float2(_NoiseSampleBias,_NoiseSampleBias), 0, 0)).rgb*2-1;
				float currentLength=_Length+noiseNormal.x * _LengthIntensity;

				//noiseNormal=normalize(noiseNormal);//不知道怎么回事，normalize后效果会很规则
				//——》问题出在这样的话_DirectionIntensity会一致！所以_DirectionIntensity严格来说应该是scale，大小和方向都已经包含在noiseNormal中了

				//找到分割线的原因了！noiseNormal的x&z不知怎的一直是同正负性
				//noiseNormal.x*=-1;//果然斜纹方向改变！
				//进一步debug发现，xyz都大于0占大多数
				//——》问题出在noise texture本身！CTMD是单通道的！——》white noise当然只有一个灰度显示！应该colorful noise！

				float3 noiseOri=noiseNormal * _OrientationIntensity;
				tangentW+=float4(noiseOri,0.0f);
				tangentW=normalize(tangentW-dot(tangentW,stalkDir)*stalkDir);
				float3 noiseDir=noiseNormal * _DirectionIntensity;

				//wind
				float3 windDirCol=tex2Dlod(_WindTex, float4(rootTerrainUV * _WindSampleScale + float2(_WindSpeedX,_WindSpeedY) * _Time.w, 0, 0)).rgb;
				//float3 windDirCol=tex2Dlod(_WindTex, float4(root.xz * _WindSampleScale + float2(_WindSpeedX,_WindSpeedY) * _Time.w, 0, 0)).rgb;
				float3 windDir=(windDirCol*2-1);
				//避免上下跳动，严格来讲应该类tangentW的处理根据ground normal而不只是平地情况
				windDir.y*=0.001f;
				windDir=normalize(windDir);
				float windForce=lerp(_WindMin, _WindMax, (sin(_Time.w*_WindFrequency)+1)*0.5f);
				float3 wind=windDir*windForce;
				//stalkDir=normalize(stalkDir+float4(noiseDir,0.0f)+float4(wind,0.0f) );
				stalkDir=normalize(stalkDir+float4(noiseDir,0.0f));

				//offset root tinily to resist coherence
				//root.xyz=root.xyz+_OffsetMax*(noiseCol.r*2-1)*normalize(_OffsetDir.xyz);

				for(int i=0;i<=NUM_STEP;i++)
				{
					//percentage
					float t = (float)i /NUM_STEP;

    				//center point
    				float4 stepStalk=normalize(stalkDir - float4(0,  t* t* _Gravity, 0, 0) +float4(t*wind,0) );
    				float4 c = root+stepStalk* (currentLength * t);

    				float4 p0=c+_Width*tangentW;
    				float4 p1=c-_Width*tangentW;
    				float4 stepNormal=float4(cross(stepStalk.xyz,tangentW.xyz),0.0f);

    				triStream.Append(ConstructorG2f(mul(UNITY_MATRIX_VP,p0),stepNormal,float2(0,t)));
					triStream.Append(ConstructorG2f(mul(UNITY_MATRIX_VP,p1),stepNormal,float2(1,t)));
				}

			}

			fixed4 PS(g2f i) : SV_Target
			{
				//先不进行light calculation，just test geometry
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 alphaValue=tex2D(_AlphaTex,i.uv);

				//这张alpha纹理本身有问题，暂且放到这修正
				if(i.uv.y+0.001f>=1.0f || i.uv.y<0.001f)
					alphaValue=fixed4(0,0,0,0);

				return fixed4(col.rgb,alphaValue.g);

				//return fixed4(0,0,1,1);
			}
			ENDCG
		}

	}
}
