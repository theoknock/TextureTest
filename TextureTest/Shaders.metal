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

constant matrix_half3x3 identity = matrix_half3x3(0,0,0,0,1,0,0,0,0);

[[stitchable]] matrix_half3x3 edges(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(1,1,1,1,-8,1,1,1,1);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

[[stitchable]] matrix_half3x3 horizontal_axis_edge(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3( -1, -1, -1,
                                                       0, 1, 0,
                                                       1,1,1);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

[[stitchable]] matrix_half3x3 vertical_axis_edge(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(1, 0, -1,
                                                       1, 1, -1,
                                                       1, 0, -1);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

[[stitchable]] matrix_half3x3 emboss(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(-2, -1, 0,
                                                       -1,  1, 1,
                                                        0,  1, 2);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

[[stitchable]] matrix_half3x3 ridges(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(-1, -1, -1,
                                                       -1,  8, -1,
                                                       -1, -1, -1);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

[[stitchable]] matrix_half3x3 gaussian_blur(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(1, 2, 1,
                                                       2, 4, 2,
                                                       1, 2, 1);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}


[[stitchable]] matrix_half3x3 box_blur(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(1,1,1,1,0,1,1,1,1);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

[[stitchable]] matrix_half3x3 sharpen(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(0,-1,0,-1,4,-1,0,-1,0);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

[[stitchable]] matrix_half3x3 ridges_alt(half coefficient) {
    matrix_half3x3 convolution_kernel = matrix_half3x3(0,-1,0,-1,4,-1,0,-1,0);
    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
    return convolution;
}

//const matrix_half3x3 convolutionKernel = matrix_half3x3(1,1,1,1,-8,1,1,1,1);// * coefficient_matrix;
//    const matrix_half3x3 convolutionKernel = matrix_half3x3(1, 0, -1, 0, 0, 0, -1, 0, 1);
//                                            //matrix_half3x3(-2, -1, 0, -1, 1, 1, 0, 1, 2); // Emboss
//                                            //matrix_half3x3(1,1,1,1,1,1,1,1,1); // Box blur (multiply by a coefficient)
//                                            //matrix_half3x3(1,2,1,2,4,2,1,2,1); // Gaussian Blur (multiply by a coefficient)
//                                            //matrix_half3x3(0,-1,0,-1,5,-1,0,-1,0); // Sharpen
//                                            //matrix_half3x3(-1,-1,-1,-1,8,-1,-1,-1,-1); // Ridge detection (2)
//                                            //matrix_half3x3(0,-1,0,-1,4,-1,0,-1,0); // Ridge detection (1)

constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

[[stitchable]]
uint2 convolution3x3GIDOffset(uint2 offset, int index) {
    switch (index) {
        case 0:
            return offset;
        case 1:
            return uint2(0, 0);
        default:
            return uint2(0, 0);
    }
}

[[stitchable]]
uint2 convolution3x3GID(uint2 gid, uint2 offset, int position, int index) {
    switch (position) {
        case 0:
            return gid + uint2(-1, 0) + convolution3x3GIDOffset(offset, index);
        case 1:
            return gid + uint2(0, 1) + convolution3x3GIDOffset(offset, index);
        case 2:
            return gid + uint2(0, -1) + convolution3x3GIDOffset(offset, index);
        case 3:
            return gid + uint2(-1, -1) + convolution3x3GIDOffset(offset, index);
        case 4:
            return gid + uint2(1, -1) + convolution3x3GIDOffset(offset, index);
        case 5:
            return gid + uint2(0, 1) + convolution3x3GIDOffset(offset, index);
        case 6:
            return gid + uint2(-1, 1) + convolution3x3GIDOffset(offset, index);
        case 7:
            return gid + uint2(1, 1) + convolution3x3GIDOffset(offset, index);
        default:
            return gid;
    }
}

[[stitchable]]
void convolution3x3(texture2d<half, access::read> inTexture, texture2d<half, access::write> outTexture, uint2 gid, matrix_half3x3 convolutionKernel, uint2 offset)
{
    // To-Do: Process an array of convolution kernels, each feeding their result into the next
    //        ...or
    uint2 leftTextureCoordinate[2] = {convolution3x3GID(gid, offset, 0, 0), convolution3x3GID(gid, offset, 0, 1)};
    uint2 rightTextureCoordinate[2] = {convolution3x3GID(gid, offset, 1, 0), convolution3x3GID(gid, offset, 1, 1)};
    uint2 topTextureCoordinate[2] = {convolution3x3GID(gid, offset, 2, 0), convolution3x3GID(gid, offset, 2, 1)};
    uint2 topLeftTextureCoordinate[2] = {convolution3x3GID(gid, offset, 3, 0), convolution3x3GID(gid, offset, 3, 1)};
    uint2 topRightTextureCoordinate[2] = {convolution3x3GID(gid, offset, 4, 0), convolution3x3GID(gid, offset, 4, 1)};
    uint2 bottomTextureCoordinate[2] = {convolution3x3GID(gid, offset, 5, 0), convolution3x3GID(gid, offset, 5, 1)};
    uint2 bottomLeftTextureCoordinate[2] = {convolution3x3GID(gid, offset, 6, 0), convolution3x3GID(gid, offset, 6, 1)};
    uint2 bottomRightTextureCoordinate[2] = {convolution3x3GID(gid, offset, 7, 0), convolution3x3GID(gid, offset, 7, 1)};
    half4 bottomLeftIntensity[2] = {inTexture.read(bottomLeftTextureCoordinate[0]).rgba, inTexture.read(bottomLeftTextureCoordinate[1]).rgba};
    half4 topRightIntensity[2] = {inTexture.read(topRightTextureCoordinate[0]).rgba, inTexture.read(topRightTextureCoordinate[1]).rgba};
    half4 topLeftIntensity[2] = {inTexture.read(topLeftTextureCoordinate[0]).rgba, inTexture.read(topLeftTextureCoordinate[1]).rgba};
    half4 bottomRightIntensity[2] = {inTexture.read(bottomRightTextureCoordinate[0]).rgba, inTexture.read(bottomRightTextureCoordinate[1]).rgba};
    half4 leftIntensity[2] = {inTexture.read(leftTextureCoordinate[0]).rgba, inTexture.read(leftTextureCoordinate[1]).rgba};
    half4 rightIntensity[2] = {inTexture.read(rightTextureCoordinate[0]).rgba, inTexture.read(rightTextureCoordinate[1]).rgba};
    half4 bottomIntensity[2] = {inTexture.read(bottomTextureCoordinate[0]).rgba, inTexture.read(bottomTextureCoordinate[1]).rgba};
    half4 topIntensity[2] = {inTexture.read(topTextureCoordinate[0]).rgba, inTexture.read(topTextureCoordinate[1]).rgba};
    
    half4 resultColor = topLeftIntensity[0] * convolutionKernel[0][0] + topIntensity[0] * convolutionKernel[0][1] + topRightIntensity[0] * convolutionKernel[0][2];
    resultColor += leftIntensity[0] * convolutionKernel[1][0] + inTexture.read(gid).rgba * convolutionKernel[1][1] + rightIntensity[0] * convolutionKernel[1][2];
    resultColor += bottomLeftIntensity[0] * convolutionKernel[2][0] + bottomIntensity[0] * convolutionKernel[2][1] + bottomRightIntensity[0] * convolutionKernel[2][2];
    
    convolutionKernel = identity;
    half4 resultColor_2 = topLeftIntensity[1] * convolutionKernel[0][0] + topIntensity[1] * convolutionKernel[0][1] + topRightIntensity[1] * convolutionKernel[0][2];
    resultColor_2 += leftIntensity[1] * convolutionKernel[1][0] + inTexture.read(gid).rgba * convolutionKernel[1][1] + rightIntensity[1] * convolutionKernel[1][2];
    resultColor_2 += bottomLeftIntensity[1] * convolutionKernel[2][0] + bottomIntensity[1] * convolutionKernel[2][1] + bottomRightIntensity[1] * convolutionKernel[2][2];
    
    half alpha = resultColor.a + (resultColor_2.a * (1.0 - resultColor.a));
    half3 color_operator_over = ((resultColor.rgb * resultColor.a) + ((resultColor_2.rgb * resultColor_2.a) * (1.0 - resultColor.a)))/alpha;
    half3 blend = resultColor_2.rgb * ((mix(mix(resultColor_2.rgb, resultColor.rgb, half3(0.4, 0.4, 0.4)),
                                            mix(resultColor_2.rgb, resultColor.rgb, half3(0.4, 0.4, 0.4)),
                                            half3(0.4, 0.4, 0.4)) * abs(resultColor_2.rgb - resultColor.rgb)));
    half3 color =  (1.0 / alpha) * half3((1.0 - resultColor_2.rgb) * (resultColor.rgb * resultColor.a) + (1.0 - resultColor.rgb) * (resultColor_2.rgb * resultColor_2.a)+ (resultColor.a * resultColor_2.a) * blend);
//    clamp((half)alpha, (half)0.0, (half)1.0);
    outTexture.write(half4(color_operator_over.rgb, alpha), gid);
}

[[stitchable]]
half4 gaussian_distribution(half4 std_dev, half4 mean, half4 variance, half4 texture)
{
//    texture = (exp(-((pow((texture - mean), 2.f) / pow(2.f * variance, 2.f)))));
//    texture = (1.f / (std_dev * sqrt(2.f * M_PI_H))) * (exp(-((pow((texture - mean), 2.f) / pow(2.f * variance, 2.f)))));
    texture = 1.0 / (1.0 + exp(-1 * variance) * (texture- (texture / 2.f)));
    return texture;
}


[[stitchable]]
void convolution3x3_exploratorium(texture2d<half, access::read> inTexture, texture2d<half, access::write> outTexture, uint2 gid, matrix_half3x3 convolutionKernel, uint2 offset)
{
    uint2 leftTextureCoordinate[2] = {convolution3x3GID(gid, offset, 0, 0), convolution3x3GID(gid, offset, 0, 1)};
    uint2 rightTextureCoordinate[2] = {convolution3x3GID(gid, offset, 1, 0), convolution3x3GID(gid, offset, 1, 1)};
    uint2 topTextureCoordinate[2] = {convolution3x3GID(gid, offset, 2, 0), convolution3x3GID(gid, offset, 2, 1)};
    uint2 topLeftTextureCoordinate[2] = {convolution3x3GID(gid, offset, 3, 0), convolution3x3GID(gid, offset, 3, 1)};
    uint2 topRightTextureCoordinate[2] = {convolution3x3GID(gid, offset, 4, 0), convolution3x3GID(gid, offset, 4, 1)};
    uint2 bottomTextureCoordinate[2] = {convolution3x3GID(gid, offset, 5, 0), convolution3x3GID(gid, offset, 5, 1)};
    uint2 bottomLeftTextureCoordinate[2] = {convolution3x3GID(gid, offset, 6, 0), convolution3x3GID(gid, offset, 6, 1)};
    uint2 bottomRightTextureCoordinate[2] = {convolution3x3GID(gid, offset, 7, 0), convolution3x3GID(gid, offset, 7, 1)};
    half4 bottomLeftIntensity[2] = {inTexture.read(bottomLeftTextureCoordinate[0]).r, inTexture.read(bottomLeftTextureCoordinate[1]).rgba};
    half4 topRightIntensity[2] = {inTexture.read(topRightTextureCoordinate[0]).r, inTexture.read(topRightTextureCoordinate[1]).rgba};
    half4 topLeftIntensity[2] = {inTexture.read(topLeftTextureCoordinate[0]).r, inTexture.read(topLeftTextureCoordinate[1]).rgba};
    half4 bottomRightIntensity[2] = {inTexture.read(bottomRightTextureCoordinate[0]).r, inTexture.read(bottomRightTextureCoordinate[1]).rgba};
    half4 leftIntensity[2] = {inTexture.read(leftTextureCoordinate[0]).r, inTexture.read(leftTextureCoordinate[1]).rgba};
    half4 rightIntensity[2] = {inTexture.read(rightTextureCoordinate[0]).r, inTexture.read(rightTextureCoordinate[1]).rgba};
    half4 bottomIntensity[2] = {inTexture.read(bottomTextureCoordinate[0]).r, inTexture.read(bottomTextureCoordinate[1]).rgba};
    half4 topIntensity[2] = {inTexture.read(topTextureCoordinate[0]).r, inTexture.read(topTextureCoordinate[1]).rgba};

    half mean = median3(inTexture.read(topTextureCoordinate[0]).r, inTexture.read(topTextureCoordinate[0]).g, inTexture.read(topTextureCoordinate[0]).b);
    half std_dev = 1.f;//inTexture.read(topTextureCoordinate[0]).b;
    half variance = mean; //sqrt(std_dev);
    half4 resultColor = gaussian_distribution(std_dev, mean, variance, topLeftIntensity[0]) + gaussian_distribution(std_dev, mean, variance, topIntensity[0]) + gaussian_distribution(std_dev, mean, variance, topRightIntensity[0]);
    resultColor += gaussian_distribution(std_dev, mean, variance, leftIntensity[0]) + gaussian_distribution(std_dev, mean, variance, inTexture.read(gid).rgba) + gaussian_distribution(std_dev, mean, variance, rightIntensity[0]);
    resultColor += gaussian_distribution(std_dev, mean, variance, bottomLeftIntensity[0]) + gaussian_distribution(std_dev, mean, variance, bottomIntensity[0]) + gaussian_distribution(std_dev, mean, variance, bottomRightIntensity[0]);
    half4 inputImageTexture = inTexture.read(gid);
    outTexture.write(fabs(half4(inputImageTexture.rgb + (inputImageTexture.rgb - median3(resultColor.r, resultColor.g, resultColor.b)), 1.0)), gid);
}

float scale(float val_old, float min_old, float max_old, float min_new, float max_new) {
    return min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
}

// Fragment function
fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
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
    half4 inputImageTexture = inTexture.read(gid);
    float grayscale = median3(inputImageTexture.r, inputImageTexture.g, inputImageTexture.b);
    float mean = 0.111115;
    float numerator = pow(grayscale - mean, 2.0);
    float variance = mean * (1.f - mean);
    float denominator = 2.f * pow(variance, 2.f);
    grayscale = 1.0 - fabs(grayscale - scale(exp(-(numerator / denominator)), -1.3, 1.7, 0.0, 1.0));
    outTexture.write(fabs(half4(grayscale, grayscale, grayscale, 1.0)), gid);
}

//    float convolution_parameters = 1.f;//.inTexture.read(gid).r;
//    float coefficient = 1.f;
//    matrix_half3x3 convolution_kernel = matrix_half3x3(convolution_parameters, convolution_parameters, convolution_parameters, convolution_parameters, convolution_parameters, convolution_parameters, convolution_parameters, convolution_parameters, convolution_parameters);
//    const matrix_half3x3 coefficient_matrix = matrix_half3x3(coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient, coefficient);
//    matrix_half3x3 convolution = convolution_kernel * coefficient_matrix;
//
//    convolution3x3_exploratorium(inTexture, outTexture, gid, identity + convolution_kernel, uint2(0,0));

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
    half4 texture = inTexture.read(gid);inTexture.read(gid);
    half4 texture_p = inTextureP.read(gid);
    half4 diff_texture = abs(texture_p - texture);
    clamp(diff_texture, 0.0, 1.0);
    //    half gray_texture = dot(diff_texture.rgb, kRec709Luma);
    half gamma_texture = 0.0;// 1.0 - pow((1.0 - gray_texture), 1.5); // invert, gamma to stretch whites (really black), invert again
    half4 out_texture = half4( diff_texture.r + gamma_texture, diff_texture.g + gamma_texture, diff_texture.b + gamma_texture, 1.0);
    clamp(out_texture, 0.0, 1.0);
    //    half4 out_texture = half4(texture.r, texture.g, texture.b, out_alpha);
    //    out_texture = pow(1.0 - out_texture, 3.0);
    //    out_texture /= 1.0 - out_texture;
    
    outTexture.write(out_texture, gid);
}
