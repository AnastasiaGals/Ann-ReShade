/*------------------.
| :: Description :: |
'-------------------/

	Ann's dumb shader
	includes the blue noise pattern from here
	https://momentsingraphics.de/BlueNoise.html
	i'm cool with you using it for whatever, if it's like a commercial thing, dm me, i'd like to know and credit would be nice
	io_person
	
*/

/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "shared/cGraphics.fxh"
#include "shared/cConvolution.fxh"
//credit for this effect goes to the people who made cshade, papadanku
/*------------------.
| :: UI Settings :: |
'------------------*/

uniform int PixelationSizeX < __UNIFORM_SLIDER_INT1
	ui_min = 1;
	ui_max = 50;
	ui_label = "Size X";
	ui_tooltip = "Size of new pixels horizontally";
	ui_category = "Pixel options";
> = 3;

uniform int PixelationSizeY < __UNIFORM_SLIDER_INT1
	ui_min = 1;
	ui_max = 50;
	ui_label = "Size Y";
	ui_tooltip = "Size of new pixels vertically";
	ui_category = "Pixel options";
> = 3;

uniform float SIG < __UNIFORM_SLIDER_FLOAT1
	ui_label = "blur deg";
	ui_category = "blur";
	ui_label= "some blur reduces flickering";
	ui_min = 0.00; ui_max = 20.0;
> = 2.0;

uniform bool greyscale  <
	ui_label = "greyscale";
	ui_category = "greyscale";
	ui_tooltip = "makes image greyscale, required for most other options";
> = 1;

uniform bool colmod  < 
	ui_label = "image single col";
	ui_category = "greyscale";
	ui_tooltip = "replaces image wtih one singular colour allowing you to see the effects of edge detection without influwence of background colour";
> = 0;

uniform float monocol < __UNIFORM_SLIDER_FLOAT1
	ui_label = "single col";
	ui_category = "greyscale";
	ui_tooltip = "picks the monochrome colour to replace the image with";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform bool dither  <
	ui_label = "dither";
	ui_category = "greyscale";
	ui_tooltip = "ditheres layered greyscale";
> = 1;

uniform float3 Greyscale_vector < __UNIFORM_COLOR_FLOAT3
	ui_label = "Custom Conversion values";
	ui_category = "greyscale";
	ui_tooltip = "greyscale along this vector";
> = float3(1., 1., 1.);

uniform float3 dinnwhite < __UNIFORM_COLOR_FLOAT3
	ui_label = "obra dinnw white";
	ui_category = "greyscale";
	ui_tooltip = "whites replaced with this";
> = float3(1., 1., 1.);

uniform float3 dinnblack < __UNIFORM_COLOR_FLOAT3
	ui_label = "obra dinnw black";
	ui_category = "greyscale";
	ui_tooltip = "blacks replaced with this";
> = float3(0., 0., 0.);

uniform float Colour_Bleed < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Grey sat";
	ui_category = "greyscale";
	ui_tooltip = "Lets some colour peak through your greyscale";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform int GreyLevel < __UNIFORM_SLIDER_INT1
	ui_min = 1;
	ui_max = 50;
	ui_label = "grey levels";
	ui_tooltip = "gives you levels of grey, 1 results means no levels";
	ui_category = "greyscale";
> = 2;

uniform bool ordered  <
	ui_label = "ordered";
	ui_category = "greyscale";
	ui_tooltip = "gives you ordered dither";
> = 0;

uniform int orderedmask  < __UNIFORM_SLIDER_INT1
	ui_min = 2;
	ui_max = 4;
	ui_label = "ordered dither mask choice";
	ui_category = "greyscale";
	ui_tooltip = "gives you ordered dither";
> = 2;

uniform float DithDeg < __UNIFORM_SLIDER_FLOAT1
	ui_label = "how far does one dither";
	ui_category = "greyscale";
	ui_tooltip = "higher values mean more tones get represented by dither";
	ui_min = 0.01; ui_max = 5.0;
> = 2.0;

uniform bool EdgeDetect < 
	ui_label = "edges";
	ui_category = "edges";
	ui_tooltip = "Introduces difference of gaussians edge detection, following options regard specificities";
> = TRUE;

uniform float SIG1 < __UNIFORM_SLIDER_FLOAT1
	ui_label = "small blur";
	ui_category = "edges";
	ui_tooltip = "Removes small noise from edges.";
	ui_min = 0.00; ui_max = 5.0;
> = 1.5;

uniform float SIG2 < __UNIFORM_SLIDER_FLOAT1
	ui_label = "big blur";
	ui_category = "edges";
	ui_tooltip = "Adds thicker edges.";
	ui_min = 0.00; ui_max = 5.0;
> = 4.5;

uniform float CONT < __UNIFORM_SLIDER_FLOAT1
	ui_label = "edge intensity";
	ui_category = "edges";
	ui_tooltip = "Multiplies big blur for sensitivity.";
	ui_min = 0.80; ui_max = 2.00;
> = 1.0;

uniform float threshold < __UNIFORM_SLIDER_FLOAT1
	ui_label = "edge treshold";
	ui_category = "edges";
	ui_tooltip = "minimal level required for edge.";
	ui_min = 0.00; ui_max = 2.0;
> = 0.03;

uniform float3 dotedge < __UNIFORM_COLOR_FLOAT3
	ui_label = "edge dot product";
	ui_category = "edges";
	ui_tooltip = "colour along wich edges are detected";
> = float3(1., 1., 1.);

uniform float inter < __UNIFORM_SLIDER_FLOAT1
	ui_label = "intercept darkness";
	ui_category = "edges";
	ui_tooltip = "darkness adjustment, the lower it goes the more sensitive all colours";
	ui_min = 0.; ui_max = 7.0;
> = 0.8;

uniform float slope < __UNIFORM_SLIDER_FLOAT1
	ui_label = "slope darkness";
	ui_category = "edges";
	ui_tooltip = "darkness adjustment, the higher it is the less sensitive brighter parts";
	ui_min = 0.0; ui_max = 5.;
> = 0.5;

uniform float range < __UNIFORM_SLIDER_FLOAT1
	ui_label = "lerprange";
	ui_category = "edges";
	ui_tooltip = "how much edge is required to go from full to no effect";
	ui_min = 0.0; ui_max = 3.;
> = 0.1;

uniform bool diag  <
	ui_label = "diagnostic";
	ui_category = "help";
	ui_tooltip = "makes a b-w slope";
> = 0;

/*-------------------------.
| :: Sampler and timers :: |
'-------------------------*/

#define AnnSampler ReShade::BackBuffer

texture BlueNoise < source ="HDR_LA_3.png" ; > { Width = 256; Height = 256; };
sampler BlueNoiseSamp { Texture = BlueNoise; AddressU = REPEAT;	AddressV = REPEAT;	AddressW = REPEAT;};

texture BLURSTORE {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler2D BLURSTOREs { Texture = BLURSTORE; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

texture smallblur {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler2D SmallBlurM { Texture = smallblur; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

texture bigblur {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler2D BigBlurM { Texture = bigblur; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

#define DITHER_MATRIX1 float3x3(0.75,-0.75,0.25,-0.5,-1,0,0.5,-0.25,1)
#define DITHER_MATRIX2 float4x4(0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5)
/*-------------.
| :: Effect :: |
'-------------*/
float3 BlurPass( float2 Tex, bool Horizontal, float SIGMA, sampler SAMP){
	//this function blurs in one direction based on the bool Horizontal
	float2 Direction = Horizontal ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 PixelSize = (1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT)) * Direction;
    float KernelSize = SIGMA * 3.0;
	if(SIGMA == 0.0)
		{
			//skips the for loop when no blurring is actually specified, saves on time
			return tex2Dlod(SAMP, float4(Tex, 0.0, 0.0)).rgb;
		}
		else
		{
			// Sample and weight center first to get even number sides
	        float TotalWeight = CConvolution_GetGaussianWeight(0.0, SIGMA);
	        float3 OutputColor = tex2D(SAMP, Tex).rgb * TotalWeight;
	
	        for(float i = 1.0; i < KernelSize; i += 2.0)
	        {
	            float LinearWeight = 0.0;
	            float LinearOffset = CConvolution_GetGaussianOffset(i, SIGMA, LinearWeight);
	            OutputColor += tex2Dlod(SAMP, float4(Tex - LinearOffset * PixelSize, 0.0, 0.0)).rgb * LinearWeight;
	            OutputColor += tex2Dlod(SAMP, float4(Tex + LinearOffset * PixelSize, 0.0, 0.0)).rgb * LinearWeight;
	            TotalWeight += LinearWeight * 2.0;
	        }
	
	        // Normalize intensity to prevent altered output
	        return OutputColor / TotalWeight;
		}
}

//this function makes the final image out of the previously calculated gaussians
float3 finisher( float2 tex ){
	float2 PixelBlock = float2(float(PixelationSizeX), float(PixelationSizeY));
	int2 pointint = trunc((BUFFER_SCREEN_SIZE / PixelBlock) * tex);
	float2 Pointer = pointint * (PixelBlock / BUFFER_SCREEN_SIZE);
	float2 POINT = Pointer + trunc(PixelBlock/2.)*BUFFER_PIXEL_SIZE;
	float3 col = tex2D(AnnSampler, POINT).rgb;
	int2 cellp = pointint % 2;
	//defines variables
	if(greyscale){
		//converts to greyscale, quantizes, adds dither
		float gry = dot(col, Greyscale_vector);
		if(diag){
			gry = Pointer.x;
		}else if(colmod){
			gry = monocol;
		}
		if (GreyLevel > 1) {
			if (dither){	
			if(ordered){
				if(orderedmask==2){
					gry = gry+((cellp.x)+(cellp.x==cellp.y)*2.-1.5)/((GreyLevel-1)*6./DithDeg);
				}else if(orderedmask==3){
					gry = gry +1.5*DITHER_MATRIX1[pointint.x % 3][pointint.y % 3] /((GreyLevel-1)*6./DithDeg);
				}else{
					gry = gry + 1.5*(DITHER_MATRIX2[pointint.x % 4][pointint.y % 4]/7.5-1 )/((GreyLevel-1)*6./DithDeg);
				}
				}else{
				gry = gry+(tex2Dlod(BlueNoiseSamp, float4(pointint/float2(256,256),0.0,0.0) ).r*DithDeg-0.5*DithDeg)/(GreyLevel-1.);
			}
			}
			if(EdgeDetect){
			float edge = smoothstep(0,1,( abs((dot((tex2Dlod(SmallBlurM ,float4(POINT,0.0,0.0))-CONT*tex2Dlod(BigBlurM,float4(POINT,0.0,0.0))).rgb, dotedge))/(dot(tex2Dlod(SmallBlurM ,float4(POINT,0.0,0.0)).rgb, dotedge)*slope+inter))- threshold) /range);
			gry = gry-sign(gry-0.5)*edge;
			}
		gry = saturate((trunc(gry*GreyLevel))/(GreyLevel-1.));
		}
	col = saturate(lerp(lerp(dinnblack, dinnwhite,gry), col, Colour_Bleed));
	}
return col;
}


float3 PS_ANN2(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target{  
	float3 color = finisher(texcoord);
	return color.rgb;
}
float3 PS_BLURh(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target{  
	float3 color = BlurPass(texcoord, TRUE, SIG, AnnSampler);
  	return color.rgb;
}
float3 PS_BLURv(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target{  
	float3 color = BlurPass(texcoord, FALSE, SIG, AnnSampler);
	return color.rgb;
}
float3 PS_DIFFhb(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target{  
	float3 color = BlurPass(texcoord, TRUE, SIG1, AnnSampler);
	return color.rgb;
}
float3 PS_DIFFvb(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target{  
	float3 color = BlurPass(texcoord, FALSE, SIG1, BLURSTOREs);
	return color.rgb;
}
float3 PS_DIFFhs(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target{  
	float3 color = BlurPass(texcoord, TRUE, SIG2, AnnSampler);
	return color.rgb;
}
float3 PS_DIFFvs(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target{  
	float3 color = BlurPass(texcoord, FALSE, SIG2, BLURSTOREs);
	return color.rgb;
}


/*-----------------.
| :: Techniques :: |
'-----------------*/
technique DINNDIFF
{
	pass BLURh2{
		VertexShader=PostProcessVS;
		PixelShader=PS_DIFFhb;
		RenderTarget = BLURSTORE; 
	}
	pass BLURv2{
		VertexShader=PostProcessVS;
		PixelShader=PS_DIFFvb;
		RenderTarget = bigblur; 
	}
	pass BLURh2s{
		VertexShader=PostProcessVS;
		PixelShader=PS_DIFFhs;
		RenderTarget = BLURSTORE; 
	}
	pass BLURv2s{
		VertexShader=PostProcessVS;
		PixelShader=PS_DIFFvs;
		RenderTarget = smallblur; 
	}
	pass BLURh{
		VertexShader=PostProcessVS;
		PixelShader=PS_BLURh;
	}
	pass BLURv{
		VertexShader=PostProcessVS;
		PixelShader=PS_BLURv;
	}
	pass ANN2{
		VertexShader=PostProcessVS;
		PixelShader=PS_ANN2;
	}
}
