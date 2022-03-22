/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#include "ShaderTypes.h"

struct RasterizerData
{
    float4 position [[position]];
    float2 textureCoordinate;
};

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant AAPLVertex *vertexArray [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer [[ buffer(AAPLVertexInputIndexViewportSize) ]])
{
    float2 pixelSpacePosition = float2(vertexArray[vertexID].position.y, -vertexArray[vertexID].position.x);
    float2 viewportSize = float2(*viewportSizePointer);
    
    RasterizerData out;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 3.0); // 3.0 = view.layer.contentsScale
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);

    return float4(colorSample);
}

constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

// Grayscale compute kernel
kernel void
grayscaleKernel(
                texture2d<half, access::read>  inTexture  [[ texture(0) ]],
                texture2d<half, access::write> outTexture [[ texture(1) ]],
                texture2d<half, access::read>  inTextureP  [[ texture(2) ]],
                uint2                          gid        [[ thread_position_in_grid ]]
                )
{
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        return;
    }

   
    half4 inputImageTexture  = inTexture.read(gid);
//    half4 inputImageTextureP  = inTextureP.read(gid);
//    half4 outputImageTexture = half4(2.0, 2.0, 2.0, 1.0) * (inputImageTextureP - inputImageTexture);
//    half  gray     = dot(inputImageTexture.rgb, kRec709Luma);
//    half  grayP     = dot(inputImageTextureP.rgb, kRec709Luma);
//    gray = (grayP - gray) + 1.0;
    outTexture.write(half4(inputImageTexture.r, inputImageTexture.g, inputImageTexture.b, 1.0), gid);
    
//    inputImageTexture = half4(gray, gray, gray, 1.0);
//
//    uint2 leftTextureCoordinate = gid + uint2(-1, 0);
//    uint2 rightTextureCoordinate = gid + uint2(0, 1);
//    uint2 topTextureCoordinate = gid + uint2(0, -1);
//    uint2 topLeftTextureCoordinate = gid + uint2(-1, -1);
//    uint2 topRightTextureCoordinate = gid + uint2(1, -1);
//    uint2 bottomTextureCoordinate = gid + uint2(0, 1);
//    uint2 bottomLeftTextureCoordinate = gid + uint2(-1, 1);
//    uint2 bottomRightTextureCoordinate = gid + uint2(1, 1);
//    half bottomLeftIntensity = (inTexture.read(bottomLeftTextureCoordinate)).r; // inTexture.read(bottomLeftTextureCoordinate);
//    float topRightIntensity = (inTexture.read(topRightTextureCoordinate)).r;
//    float topLeftIntensity = (inTexture.read(topLeftTextureCoordinate)).r;
//    float bottomRightIntensity = (inTexture.read(bottomRightTextureCoordinate)).r;
//    float leftIntensity = (inTexture.read(leftTextureCoordinate)).r;
//    float rightIntensity = (inTexture.read(rightTextureCoordinate)).r;
//    float bottomIntensity = (inTexture.read(bottomTextureCoordinate)).r;
//    float topIntensity = (inTexture.read(topTextureCoordinate)).r;
//    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
//    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
//    float mag = 1.0 - (length(float2(h, v)) * length(float2(9 / 0.75, 16 / 1.333333)));
//
//    outTexture.write(half4(mag, mag, mag, 1.0), gid);
    
    
}

