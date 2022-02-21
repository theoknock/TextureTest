//
//  Renderer.m
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import <simd/simd.h>
#import <ModelIO/ModelIO.h>

#import "Renderer.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "ShaderTypes.h"


static const NSUInteger MaxBuffersInFlight = 3;
static unsigned int rotation_degrees;
@implementation Renderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;

    id <MTLBuffer> _dynamicUniformBuffer[MaxBuffersInFlight];
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    id <MTLTexture> _colorMap;
    MTLVertexDescriptor *_mtlVertexDescriptor;

    uint8_t _uniformBufferIndex;

    matrix_float4x4 _projectionMatrix;

    float _rotation;

    MTKMesh *_mesh;
    void(^create_texture)(CVPixelBufferRef);

}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    self = [super init];
    if(self)
    {        
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(MaxBuffersInFlight);
        [self _loadMetalWithView:view];
        [self _loadAssets];
        
        create_texture = ^{
            MTLPixelFormat pixelFormat = view.colorPixelFormat;
            CFStringRef textureCacheKeys[2] = { kCVMetalTextureCacheMaximumTextureAgeKey, kCVMetalTextureUsage };
            float maximumTextureAge = (1.0); // / view.preferredFramesPerSecond);
            CFNumberRef maximumTextureAgeValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &maximumTextureAge);
            MTLTextureUsage textureUsage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite;
            CFNumberRef textureUsageValue = CFNumberCreate(NULL, kCFNumberNSIntegerType, &textureUsage);
            CFTypeRef textureCacheValues[2] = { maximumTextureAgeValue, textureUsageValue };
            CFIndex textureCacheAttributesCount = 2;
            CFDictionaryRef cacheAttributes = CFDictionaryCreate(NULL, (const void **)textureCacheKeys, (const void **)textureCacheValues, textureCacheAttributesCount, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            
            CVMetalTextureCacheRef textureCache;
            CVMetalTextureCacheCreate(NULL, cacheAttributes, self->_device, NULL, &textureCache);
//            CFShow(cacheAttributes);
            CFRelease(textureUsageValue);
            CFRelease(cacheAttributes);
            
            return ^ (CVPixelBufferRef _Nonnull pixel_buffer) {
                @autoreleasepool {
                    __autoreleasing id<MTLTexture> texture = nil;
                    CVPixelBufferLockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
                    {
                        CVMetalTextureRef metalTextureRef = NULL;
                        CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixel_buffer, cacheAttributes, pixelFormat, CVPixelBufferGetWidth(pixel_buffer), CVPixelBufferGetHeight(pixel_buffer), 0, &metalTextureRef);
                        _colorMap = CVMetalTextureGetTexture(metalTextureRef);
                        CFRelease(metalTextureRef);
                    }
                    CVPixelBufferUnlockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
                }
            };
        }();
        
        [VideoCamera setAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)self];
    }

    return self;
}

- (void)_loadMetalWithView:(nonnull MTKView *)view;
{
    /// Load Metal state objects and initialize renderer dependent view properties

    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    view.sampleCount = 1;

    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;

    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;

    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = 12;
    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stride = 8;
    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = 1;
    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    id <MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

    id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"MyPipeline";
    pipelineStateDescriptor.sampleCount = view.sampleCount;
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;

    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState)
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }

    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

    for(NSUInteger i = 0; i < MaxBuffersInFlight; i++)
    {
        _dynamicUniformBuffer[i] = [_device newBufferWithLength:sizeof(Uniforms)
                                                        options:MTLResourceStorageModeShared];

        _dynamicUniformBuffer[i].label = @"UniformBuffer";
    }

    _commandQueue = [_device newCommandQueue];
}

- (void)_loadAssets
{
    /// Load assets into metal objects

    NSError *error;

    MTKMeshBufferAllocator *metalAllocator = [[MTKMeshBufferAllocator alloc]
                                              initWithDevice: _device];
    
    MDLMesh *mdlMesh = [MDLMesh newPlaneWithDimensions:(vector_float2){(1.3333333333 * UIScreen.mainScreen.scale), (0.75 * UIScreen.mainScreen.scale)}
                                              segments:(vector_uint2){1, 1}
                                          geometryType:MDLGeometryTypeTriangles\
                                             allocator:metalAllocator];
    
//    MDLMesh *mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3){2, 2, 2}
//                                            segments:(vector_uint3){4, 4, 4}
//                                        geometryType:MDLGeometryTypeQuads
//                                       inwardNormals:YES
//                                           allocator:metalAllocator];
                                   

    MDLVertexDescriptor *mdlVertexDescriptor =
    MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);

    mdlVertexDescriptor.attributes[VertexAttributePosition].name  = MDLVertexAttributePosition;
    mdlVertexDescriptor.attributes[VertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;

    mdlMesh.vertexDescriptor = mdlVertexDescriptor;

    _mesh = [[MTKMesh alloc] initWithMesh:mdlMesh
                                   device:_device
                                    error:&error];

    if(!_mesh || error)
    {
        NSLog(@"Error creating MetalKit mesh %@", error.localizedDescription);
    }
}

//- (void)_updateGameState:(nonnull MTKView *)view
//{
//    Uniforms * uniforms = (Uniforms*)_dynamicUniformBuffer[_uniformBufferIndex].contents;
//
//    uniforms->projectionMatrix = _projectionMatrix;
//
//    vector_float3 rotationAxis = {1, 1, 1};
//    matrix_float4x4 modelMatrix = matrix4x4_rotation(_rotation, rotationAxis);
//    matrix_float4x4 viewMatrix = matrix4x4_translation(0.0, 0.0, -1.0);
//
//    uniforms->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
//
//    _rotation = degreesToRadians(112.5); //(_rotation > degreesToRadians(360.0)) ? 0.0 : _rotation + degreesToRadians(2.0);
////    CATransform3D rotation = CATransform3DMakeRotation(degreesToRadians(180.0), 1.0, 0.0, 0.0);
////    view.layer.transform   = CATransform3DTranslate(rotation, 0.0, 0.0, 0.0);
//}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {

     }];

   MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder pushDebugGroup:@"DrawBox"];

        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];

        for (NSUInteger bufferIndex = 0; bufferIndex < _mesh.vertexBuffers.count; bufferIndex++)
        {
            MTKMeshBuffer *vertexBuffer = _mesh.vertexBuffers[bufferIndex];
            if((NSNull*)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        [renderEncoder setFragmentTexture:_colorMap
                                  atIndex:TextureIndexColor];

        for(MTKSubmesh *submesh in _mesh.submeshes)
        {
            [renderEncoder drawIndexedPrimitives:submesh.primitiveType
                                      indexCount:submesh.indexCount
                                       indexType:submesh.indexType
                                     indexBuffer:submesh.indexBuffer.buffer
                               indexBufferOffset:submesh.indexBuffer.offset];
        }

        [renderEncoder popDebugGroup];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    //
}


- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    create_texture(CMSampleBufferGetImageBuffer(sampleBuffer));
}

@end
