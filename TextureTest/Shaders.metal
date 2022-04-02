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

/*
    Stitchable functions
 */

//const matrix_half3x3 convolutionKernel = matrix_half3x3(1,1,1,1,-8,1,1,1,1);// * coefficient_matrix;
//    const matrix_half3x3 convolutionKernel = matrix_half3x3(1, 0, -1, 0, 0, 0, -1, 0, 1);
//                                            //matrix_half3x3(-2, -1, 0, -1, 1, 1, 0, 1, 2); // Emboss
//                                            //matrix_half3x3(-1,-1,-1,-1,8,-1,-1,-1,-1); // Ridge detection (2)
//                                            //matrix_half3x3(-1,-1,-1,-1,8,-1,-1,-1,-1); // Ridge detection (2)
//                                            //matrix_half3x3(1,1,1,1,1,1,1,1,1); // Box blur (multiply by a coefficient)
//                                            //matrix_half3x3(1,2,1,2,4,2,1,2,1); // Gaussian Blur (multiply by a coefficient)
//                                            //matrix_half3x3(0,-1,0,-1,5,-1,0,-1,0); // Sharpen
//                                            //matrix_half3x3(-1,-1,-1,-1,8,-1,-1,-1,-1); // Ridge detection (2)
//                                            //matrix_half3x3(0,-1,0,-1,4,-1,0,-1,0); // Ridge detection (1)

[[stitchable]]
half3 convolution3x3(texture2d<half, access::read> inTexture, uint2 gid, matrix_half3x3 convolutionKernel, half coefficient)
{
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);

    
    
    uint2 leftTextureCoordinate = gid + uint2(-1, 0);
    uint2 rightTextureCoordinate = gid + uint2(0, 1);
    uint2 topTextureCoordinate = gid + uint2(0, -1);
    uint2 topLeftTextureCoordinate = gid + uint2(-1, -1);
    uint2 topRightTextureCoordinate = gid + uint2(1, -1);
    uint2 bottomTextureCoordinate = gid + uint2(0, 1);
    uint2 bottomLeftTextureCoordinate = gid + uint2(-1, 1);
    uint2 bottomRightTextureCoordinate = gid + uint2(1, 1);
    half3 bottomLeftIntensity = inTexture.read(bottomLeftTextureCoordinate).rgb;
    half3 topRightIntensity = inTexture.read(topRightTextureCoordinate).rgb;
    half3 topLeftIntensity = inTexture.read(topLeftTextureCoordinate).rgb;
    half3 bottomRightIntensity = inTexture.read(bottomRightTextureCoordinate).rgb;
    half3 leftIntensity = inTexture.read(leftTextureCoordinate).rgb;
    half3 rightIntensity = inTexture.read(rightTextureCoordinate).rgb;
    half3 bottomIntensity = inTexture.read(bottomTextureCoordinate).rgb;
    half3 topIntensity = inTexture.read(topTextureCoordinate).rgb;
    
    half3 resultColor = topLeftIntensity * convolutionKernel[0][0] + topIntensity * convolutionKernel[0][1] + topRightIntensity * convolutionKernel[0][2];
    resultColor += leftIntensity * convolutionKernel[1][0] + inTexture.read(gid).rgb * convolutionKernel[1][1] + rightIntensity * convolutionKernel[1][2];
    resultColor += bottomLeftIntensity * convolutionKernel[2][0] + bottomIntensity * convolutionKernel[2][1] + bottomRightIntensity * convolutionKernel[2][2];
    
    return resultColor;
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

kernel void
computeKernel(
               texture2d<half, access::read>  inTexture  [[ texture(0) ]],
               texture2d<half, access::write> outTexture [[ texture(1) ]],
               texture2d<half, access::read>  inTextureP [[ texture(2) ]],
               uint2                          gid        [[ thread_position_in_grid ]]
               )
{
    const half3 coefficient = convolution3x3(inTexture, gid, matrix_half3x3(1,1,1,1,-8,1,1,1,1), 1);

    outTexture.write(half4(coefficient, 1.0), gid);
}

/*
 
 
 
 */

// Renders an outline of the texture using the Sobel method for detecting edges
kernel void
wackySobelEdgeDetectionKernelWithConvolution3x3(
                         texture2d<half, access::read>  inTexture  [[ texture(0) ]],
                         texture2d<half, access::write> outTexture [[ texture(1) ]],
                         texture2d<half, access::read>  inTextureP [[ texture(2) ]],
                         uint2                          gid        [[ thread_position_in_grid ]]
                         )
{
    uint2 leftTextureCoordinate = gid + uint2(-1, 0);
    uint2 rightTextureCoordinate = gid + uint2(0, 1);
    uint2 topTextureCoordinate = gid + uint2(0, -1);
    uint2 topLeftTextureCoordinate = gid + uint2(-1, -1);
    uint2 topRightTextureCoordinate = gid + uint2(1, -1);
    uint2 bottomTextureCoordinate = gid + uint2(0, 1);
    uint2 bottomLeftTextureCoordinate = gid + uint2(-1, 1);
    uint2 bottomRightTextureCoordinate = gid + uint2(1, 1);
    half3 bottomLeftIntensity = inTexture.read(bottomLeftTextureCoordinate).rgb;
    half3 topRightIntensity = inTexture.read(topRightTextureCoordinate).rgb;
    half3 topLeftIntensity = inTexture.read(topLeftTextureCoordinate).rgb;
    half3 bottomRightIntensity = inTexture.read(bottomRightTextureCoordinate).rgb;
    half3 leftIntensity = inTexture.read(leftTextureCoordinate).rgb;
    half3 rightIntensity = inTexture.read(rightTextureCoordinate).rgb;
    half3 bottomIntensity = inTexture.read(bottomTextureCoordinate).rgb;
    half3 topIntensity = inTexture.read(topTextureCoordinate).rgb;
    
    half coefficient_h = half(2.0);
    half coefficient_v = half(2.0);
    half3 h = -topLeftIntensity - coefficient_h * topIntensity - topRightIntensity + bottomLeftIntensity + coefficient_h * bottomIntensity + bottomRightIntensity;
    half3 v = -bottomLeftIntensity - coefficient_v * leftIntensity - topLeftIntensity + bottomRightIntensity + coefficient_v * rightIntensity + topRightIntensity;
    
    half mag;
    float2 multiplier = float2(2.0, 2.0);
    mag = length(float2(h.r, v.r)) * length(multiplier);
    mag *= mag;
    half4 outputImageTexture = half4(mag, mag, mag, 1.0 + (mag / (1 - mag))); // (inputImageTextureP - inputImageTexture) * averageImageTextures;
    clamp(outputImageTexture, 0.0, 1.0);
    
//    outTexture.write(half4(half3(outputImageTexture.rgb), (half)step((half)0.0, (half)dot(inTexture.read(gid).rgb, kRec709Luma))), gid);
    
    const matrix_half3x3 convolutionKernel = matrix_half3x3(-1,-1,-1,-1,8,-1,-1,-1,-1); // Ridge detection (2)
                                            //matrix_half3x3(1,1,1,1,1,1,1,1,1); // Box blur
                                            //matrix_half3x3(1,2,1,2,4,2,1,2,1); // Gaussian Blur
                                            //matrix_half3x3(0,-1,0,-1,5,-1,0,-1,0); // Sharpen
                                            //matrix_half3x3(0,-1,0,-1,4,-1,0,-1,0); // Ridge detection (1)
    
    half3 resultColor = topLeftIntensity * convolutionKernel[0][0] + topIntensity * convolutionKernel[0][1] + topRightIntensity * convolutionKernel[0][2];
    resultColor += leftIntensity * convolutionKernel[1][0] + outputImageTexture.rgb * convolutionKernel[1][1] + rightIntensity * convolutionKernel[1][2];
    resultColor += bottomLeftIntensity * convolutionKernel[2][0] + bottomIntensity * convolutionKernel[2][1] + bottomRightIntensity * convolutionKernel[2][2];
    
    outTexture.write(half4(resultColor, 1.0), gid);
}























constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

// Brightens dark images by dividing the texture by its inverse without burning out the highlights (clamp)
// To-Do: an overlay blend mode kernel
kernel void
divideInverseKernel(
                    texture2d<half, access::read>  inTexture  [[ texture(0) ]],
                    texture2d<half, access::write> outTexture [[ texture(1) ]],
                    texture2d<half, access::read>  inTextureP  [[ texture(2) ]],
                    uint2                          gid        [[ thread_position_in_grid ]]
                    )
{
    //    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    //    {
    //        return;
    //    }
    
    half4 inputImageTexture  = inTexture.read(gid);
    //    half4 negativeInputImageTexture = ( 1.0 - inTexture.read(gid));
    //    negativeInputImageTexture.rgb = (half3)pow(negativeInputImageTexture.rgb, half3(3.0, 3.0, 3.0));
    //    negativeInputImageTexture.rgb = (half3)pow(negativeInputImageTexture.rgb, half3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0));
    //    negativeInputImageTexture.rgb = 1.0 - negativeInputImageTexture.rgb;
    //    clamp(negativeInputImageTexture, 0.0, 1.0);
    //    half4 outputImageTexture = inputImageTexture / negativeInputImageTexture;
    //    clamp(outputImageTexture, 0.0, 1.0);
    //    half negativeInputImageTextureAlpha = dot(negativeInputImageTexture.rgb, kRec709Luma);
    
    outTexture.write(inputImageTexture, gid);
}

// Renders an outline of the texture using the Sobel method for detecting edges
kernel void
sobelEdgeDetectionKernel(
                         texture2d<half, access::read>  inTexture  [[ texture(0) ]],
                         texture2d<half, access::write> outTexture [[ texture(1) ]],
                         texture2d<half, access::read>  inTextureP [[ texture(2) ]],
                         uint2                          gid        [[ thread_position_in_grid ]]
                         )
{
    uint2 leftTextureCoordinate = gid + uint2(-1, 0);
    uint2 rightTextureCoordinate = gid + uint2(0, 1);
    uint2 topTextureCoordinate = gid + uint2(0, -1);
    uint2 topLeftTextureCoordinate = gid + uint2(-1, -1);
    uint2 topRightTextureCoordinate = gid + uint2(1, -1);
    uint2 bottomTextureCoordinate = gid + uint2(0, 1);
    uint2 bottomLeftTextureCoordinate = gid + uint2(-1, 1);
    uint2 bottomRightTextureCoordinate = gid + uint2(1, 1);
    half bottomLeftIntensity = dot((inTexture.read(bottomLeftTextureCoordinate)).rgb, kRec709Luma);
    half topRightIntensity = dot((inTexture.read(topRightTextureCoordinate)).rgb, kRec709Luma);
    half topLeftIntensity = dot((inTexture.read(topLeftTextureCoordinate)).rgb, kRec709Luma);
    half bottomRightIntensity = dot((inTexture.read(bottomRightTextureCoordinate)).rgb, kRec709Luma);
    half leftIntensity = dot((inTexture.read(leftTextureCoordinate)).rgb, kRec709Luma);
    half rightIntensity = dot((inTexture.read(rightTextureCoordinate)).rgb, kRec709Luma);
    half bottomIntensity = dot((inTexture.read(bottomTextureCoordinate)).rgb, kRec709Luma);
    half topIntensity = dot((inTexture.read(topTextureCoordinate)).rgb, kRec709Luma);
    
    half coefficient_h = half(2.0);
    half coefficient_v = half(2.0);
    half h = -topLeftIntensity - coefficient_h * topIntensity - topRightIntensity + bottomLeftIntensity + coefficient_h * bottomIntensity + bottomRightIntensity;
    half v = -bottomLeftIntensity - coefficient_v * leftIntensity - topLeftIntensity + bottomRightIntensity + coefficient_v * rightIntensity + topRightIntensity;
    
    half mag;
    float2 multiplier = float2(2.0, 2.0);
    mag = length(float2(h, v)) * length(multiplier);
    mag *= mag;
    half4 outputImageTexture = half4(mag, mag, mag, 1.0 + (mag / (1 - mag))); // (inputImageTextureP - inputImageTexture) * averageImageTextures;
    clamp(outputImageTexture, 0.0, 1.0);
    
    outTexture.write(half4(half3(outputImageTexture.rgb), (half)step((half)0.0, (half)dot(inTexture.read(gid).rgb, kRec709Luma))), gid);
}


kernel void
frameDifferencingKernel(
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
    half4 averageImageTextures  = (inputImageTexture + inputImageTexture) * 0.5;
    half4 outputImageTexture = inputImageTexture / ( 1.0 - inputImageTexture);
    clamp(outputImageTexture, 0.0, 1.0);
    
    half4 inputImageTextureP  = inTextureP.read(gid);
    half4 averageImageTexturesP  = (inputImageTextureP + inputImageTextureP) * 0.5;
    half4 outputImageTextureP = inputImageTextureP / ( 1.0 - inputImageTextureP);
    clamp(outputImageTextureP, 0.0, 1.0);
    
    half4 averageDifference = (outputImageTextureP - outputImageTexture) * ((averageImageTextures + averageImageTexturesP) * 0.5);
    averageDifference = averageDifference / ( 1.0 - averageDifference);
    averageDifference  = (averageDifference + averageDifference) * 0.5;
    
    clamp(averageDifference, 0.0, 1.0);
    
    outTexture.write(half4(averageDifference.r, averageDifference.g, averageDifference.b, 1.0), gid);
}

kernel void
frameDifferencingBasicKernel(
                             texture2d<half, access::read>  inTexture  [[ texture(0) ]],
                             texture2d<half, access::write> outTexture [[ texture(1) ]],
                             texture2d<half, access::read>  inTextureP  [[ texture(2) ]],
                             uint2                          gid        [[ thread_position_in_grid ]]
                             )
{
    //    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    //    {
    //        return;
    //    }
    
    half4 texture = inTexture.read(gid);
    half4 texture_p = inTextureP.read(gid);
    half4 diff_texture = abs(texture_p - texture);
    clamp(diff_texture, 0.0, 1.0);
    half gray_texture = dot(diff_texture.rgb, kRec709Luma);
    half gamma_texture = 0.0;// 1.0 - pow((1.0 - gray_texture), 1.5); // invert, gamma to stretch whites (really black), invert again
    half4 out_texture = half4( diff_texture.r + gamma_texture, diff_texture.g + gamma_texture, diff_texture.b + gamma_texture, 1.0);
    clamp(out_texture, 0.0, 1.0);
    //    half4 out_texture = half4(texture.r, texture.g, texture.b, out_alpha);
    //    out_texture = pow(1.0 - out_texture, 3.0);
    //    out_texture /= 1.0 - out_texture;
    
    outTexture.write(out_texture, gid);
}
