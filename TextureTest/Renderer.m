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

@interface Renderer ()

@property (strong, nonatomic, readwrite) __block id<MTLDevice>  device;
//@property (strong, nonatomic, readwrite) __block id<MTLCommandQueue> commandQueue;
@property (strong, nonatomic, readwrite) __block id<MTLCaptureScope> captureScope;

@property (strong, nonatomic, readwrite) __block id<MTLLibrary> library;
@property (strong, nonatomic, readwrite) __block NSMutableDictionary<NSString *, id<MTLFunction>> * functions;
@property (strong, nonatomic, readwrite) __block id<MTLComputePipelineState> computePipelineState;
@property (nonatomic, readwrite) __block MTLSize gridSize;
@property (nonatomic, readwrite) __block MTLSize threadgroupsPerGrid;
@property (nonatomic, readwrite) __block MTLSize threadsPerThreadgroup;

@end

@implementation Renderer
{
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    id <MTLTexture> _colorMap;
    id <MTLTexture> _colorMapPrev;
    id<MTLTexture> computeTexture;
    //    MTLVertexDescriptor *_mtlVertexDescriptor;
    //    uint8_t _uniformBufferIndex;
    //    matrix_float4x4 _projectionMatrix;
    //    float _rotation;
    //    MTKMesh *_mesh;
    
    id<MTLTexture>(^create_texture)(CVPixelBufferRef);
    
    // The Metal buffer that holds the vertex data.
    id<MTLBuffer> _vertices;
    
    // The number of vertices in the vertex buffer.
    NSUInteger _numVertices;
    
    // The current size of the view.
    vector_uint2 _viewportSize;
    
}

//-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
//{
//    self = [super init];
//    if(self)
//    {
//        _device = view.device;
//
//        [self _loadMetalWithView:view];
//        [self _loadAssets];
//
//        create_texture = ^{
//            MTLPixelFormat pixelFormat = view.colorPixelFormat;
//            CFStringRef textureCacheKeys[2] = { kCVMetalTextureCacheMaximumTextureAgeKey, kCVMetalTextureUsage };
//            float maximumTextureAge = (1.0); // / view.preferredFramesPerSecond);
//            CFNumberRef maximumTextureAgeValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &maximumTextureAge);
//            MTLTextureUsage textureUsage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite;
//            CFNumberRef textureUsageValue = CFNumberCreate(NULL, kCFNumberNSIntegerType, &textureUsage);
//            CFTypeRef textureCacheValues[2] = { maximumTextureAgeValue, textureUsageValue };
//            CFIndex textureCacheAttributesCount = 2;
//            CFDictionaryRef cacheAttributes = CFDictionaryCreate(NULL, (const void **)textureCacheKeys, (const void **)textureCacheValues, textureCacheAttributesCount, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//
//            CVMetalTextureCacheRef textureCache;
//            CVMetalTextureCacheCreate(NULL, cacheAttributes, self->_device, NULL, &textureCache);
//            //            CFShow(cacheAttributes);
//            CFRelease(textureUsageValue);
//            CFRelease(cacheAttributes);
//
//            return ^ id <MTLTexture> (CVPixelBufferRef _Nonnull pixel_buffer) {
//                __autoreleasing id<MTLTexture> texture = nil;
//                @autoreleasepool {
//                    CVPixelBufferLockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
//                    {
//                        CVMetalTextureRef metalTextureRef = NULL;
//                        CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixel_buffer, cacheAttributes, pixelFormat, CVPixelBufferGetWidth(pixel_buffer), CVPixelBufferGetHeight(pixel_buffer), 0, &metalTextureRef);
//                        texture = CVMetalTextureGetTexture(metalTextureRef);
//                        CFRelease(metalTextureRef);
//                    }
//                    CVPixelBufferUnlockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
//                }
//                return texture;
//            };
//        }();
//    }
//
//    return self;
//}
//
//- (void)_loadMetalWithView:(nonnull MTKView *)view {
//    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
//    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
//    view.sampleCount = 1;
//
//    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
//
//    _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
//    _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
//    _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;
//
//    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
//    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
//    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;
//
//    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = 12;
//    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
//    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;
//
//    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stride = 8;
//    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = 1;
//    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;
//
//    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
//
//    id <MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
//
//    id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
//
//    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
//    pipelineStateDescriptor.label = @"MyPipeline";
//    pipelineStateDescriptor.sampleCount = view.sampleCount;
//    pipelineStateDescriptor.vertexFunction = vertexFunction;
//    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
//    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
//    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
//    pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
//    pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;
//
//    NSError *error = NULL;
//    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
//    if (!_pipelineState)
//    {
//        NSLog(@"Failed to created pipeline state, error %@", error);
//    }
//
//    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
//    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
//    depthStateDesc.depthWriteEnabled = YES;
//    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
//
//    _commandQueue = [_device newCommandQueue];
//}
//
//- (void)_loadAssets {
//
//    NSError *error;
//
//    MTKMeshBufferAllocator *metalAllocator = [[MTKMeshBufferAllocator alloc]
//                                              initWithDevice: _device];
//
//    MDLMesh *mdlMesh = [MDLMesh newPlaneWithDimensions:(vector_float2){1,1}// {(1.3333333333 * UIScreen.mainScreen.nativeScale), (UIScreen.mainScreen.nativeScale)}
//                                              segments:(vector_uint2){2, 2}
//                                          geometryType:MDLGeometryTypeQuads
//                                             allocator:metalAllocator];
//
////    MDLMesh *mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3){2, 2, 2}
////                                            segments:(vector_uint3){4, 4, 4}
////                                        geometryType:MDLGeometryTypeQuads
////                                       inwardNormals:YES
////                                           allocator:metalAllocator];
//
//
//    MDLVertexDescriptor *mdlVertexDescriptor =
//    MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);
//
//    mdlVertexDescriptor.attributes[VertexAttributePosition].name  = MDLVertexAttributePosition;
//    mdlVertexDescriptor.attributes[VertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
//
//    mdlMesh.vertexDescriptor = mdlVertexDescriptor;
//
//    _mesh = [[MTKMesh alloc] initWithMesh:mdlMesh
//                                   device:_device
//                                    error:&error];
//
//    if(!_mesh || error)
//    {
//        NSLog(@"Error creating MetalKit mesh %@", error.localizedDescription);
//    }
//}
//
//- (void)drawInMTKView:(nonnull MTKView *)view
//{
//    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
//    commandBuffer.label = @"MyCommand";
//
//    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
//     {
//
//     }];
//
//   MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
//
//    if(renderPassDescriptor != nil)
//    {
//        id <MTLRenderCommandEncoder> renderEncoder =
//        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
//        renderEncoder.label = @"MyRenderEncoder";
//
////        [renderEncoder pushDebugGroup:@"DrawBox"];
//
////        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
////        [renderEncoder setCullMode:MTLCullModeBack];
//        [renderEncoder setRenderPipelineState:_pipelineState];
//        [renderEncoder setDepthStencilState:_depthState];
//
//        for (NSUInteger bufferIndex = 0; bufferIndex < _mesh.vertexBuffers.count; bufferIndex++)
//        {
//            MTKMeshBuffer *vertexBuffer = _mesh.vertexBuffers[bufferIndex];
//            if((NSNull*)vertexBuffer != [NSNull null])
//            {
//                [renderEncoder setVertexBuffer:vertexBuffer.buffer
//                                        offset:vertexBuffer.offset
//                                       atIndex:bufferIndex];
//            }
//        }
//
//        [renderEncoder setFragmentTexture:_colorMap
//                                  atIndex:TextureIndexColor];
//
//        for(MTKSubmesh *submesh in _mesh.submeshes)
//        {
//            [renderEncoder drawIndexedPrimitives:submesh.primitiveType
//                                      indexCount:submesh.indexCount
//                                       indexType:submesh.indexType
//                                     indexBuffer:submesh.indexBuffer.buffer
//                               indexBufferOffset:submesh.indexBuffer.offset];
//        }
//
//        [renderEncoder popDebugGroup];
//
//        [renderEncoder endEncoding];
//
//        [commandBuffer presentDrawable:view.currentDrawable];
//    }
//
//    [commandBuffer commit];
//}
//
//- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
//    [view setDrawableSize:CGSizeMake(size.width/view.layer.contentsScale, size.height/view.layer.contentsScale)];
//}

@synthesize computePipelineState = _computePipelineState,
gridSize = _gridSize,
threadgroupsPerGrid = _threadgroupsPerGrid,
threadsPerThreadgroup = _threadsPerThreadgroup;

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;
        mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
        mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
        mtkView.sampleCount = 1;
        
        id<MTLLibrary> defaultLibrary = [mtkView.preferredDevice newDefaultLibrary];
        
        create_texture = ^{
            MTLPixelFormat pixelFormat = mtkView.colorPixelFormat;
            CFStringRef textureCacheKeys[2] = { kCVMetalTextureCacheMaximumTextureAgeKey, kCVMetalTextureUsage };
            float maximumTextureAge = 1.0; //(mtkView.preferredFramesPerSecond);
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
            
            return ^ id<MTLTexture> (CVPixelBufferRef _Nonnull pixel_buffer) {
                
                __autoreleasing id<MTLTexture> texture = nil;
                @autoreleasepool {
                    CVPixelBufferLockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
                    {
                        CVMetalTextureRef metalTextureRef = NULL;
                        CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixel_buffer, cacheAttributes, pixelFormat, CVPixelBufferGetWidth(pixel_buffer), CVPixelBufferGetHeight(pixel_buffer), 0, &metalTextureRef);
                        texture = CVMetalTextureGetTexture(metalTextureRef);
                        CFRelease(metalTextureRef);
                    }
                    CVPixelBufferUnlockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
                }
                return texture;
            };
        }();
        
        // Set up a simple MTLBuffer with vertices which include texture coordinates
        const float dim_a  = CGRectGetMaxX(UIScreen.mainScreen.bounds);
        const float dim_b  = CGRectGetMaxX(UIScreen.mainScreen.bounds) * (3840.f/2160.f); // CMVideoDimensions(height,width) // CVPixelBufferGetHeight(pixel_buffer), CVPixelBufferGetWidth(pixel_buffer)
        AAPLVertex quadVertices[] =
        {
            //    Pixel positions       Texture coordinates
            { {  dim_b,  -dim_a },  { 1.f, 1.f } },
            { { -dim_b,  -dim_a },  { 0.f, 1.f } },
            { { -dim_b,   dim_a },  { 0.f, 0.f } },
            
            { {  dim_b,  -dim_a },  { 1.f, 1.f } },
            { { -dim_b,   dim_a },  { 0.f, 0.f } },
            { {  dim_b,   dim_a },  { 1.f, 0.f } },
        };
        
        // Create a vertex buffer, and initialize it with the quadVertices array
        _vertices = [_device newBufferWithBytes:quadVertices
                                         length:sizeof(quadVertices)
                                        options:MTLResourceStorageModeShared];
        
        // Calculate the number of vertices by dividing the byte length by the size of each vertex
        _numVertices = sizeof(quadVertices) / sizeof(AAPLVertex);
        
        /// Create the render pipeline.
        
        // Load the shaders from the default library
        //        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"];
        id<MTLFunction> computeKernel = [defaultLibrary newFunctionWithName:@"grayscaleKernel"];
        
        // Set up a descriptor for creating a pipeline state object
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"MyPipeline";
        pipelineStateDescriptor.sampleCount = mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
        pipelineStateDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
        
        __autoreleasing NSError * error = nil;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        if (!_pipelineState)
        {
            NSLog(@"Failed to created pipeline state, error %@", error);
        }
        
        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
        depthStateDesc.depthWriteEnabled = YES;
        _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
        
        _computePipelineState = [_device newComputePipelineStateWithFunction:computeKernel error:&error];
        NSAssert(_computePipelineState, @"Failed to create compute pipeline state: %@", error);
        
        NSUInteger w = _computePipelineState.threadExecutionWidth;
        NSUInteger h = _computePipelineState.maxTotalThreadsPerThreadgroup / w;
        _threadsPerThreadgroup = MTLSizeMake(w, h, 1);
        _threadgroupsPerGrid   = MTLSizeMake((3840 + w - 1) / w,
                                             (2160  + h - 1) / h,
                                             1);
        
        NSLog(@"threadsPerThreadgroup: %lu x %lu\tthreadgroupsPerGrid: %lu x %lu",
              _threadsPerThreadgroup.width,
              _threadsPerThreadgroup.height,
              _threadgroupsPerGrid.width,
              _threadgroupsPerGrid.height);
        
        MTLTextureDescriptor * descriptor = [MTLTextureDescriptor
                                             texture2DDescriptorWithPixelFormat:mtkView.colorPixelFormat
                                             width:2160
                                             height:1284
                                             mipmapped:FALSE];
        [descriptor setUsage:MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget];
        computeTexture = [_device newTextureWithDescriptor:descriptor];
        
        
        _commandQueue = [_device newCommandQueue];
    }
    
    return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable to pass to the vertex shader.
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

/// Called whenever the view needs to render a frame
- (void)drawInMTKView:(nonnull MTKView *)view
{
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    //    [commandBuffer enqueue];
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipelineState];
    [computeEncoder setTexture:_colorMap
                       atIndex:0];
    [computeEncoder setTexture:computeTexture atIndex:1];
    [computeEncoder setTexture:_colorMapPrev
                       atIndex:2];
    [computeEncoder dispatchThreadgroups:_threadgroupsPerGrid
                   threadsPerThreadgroup:_threadsPerThreadgroup];
    [computeEncoder endEncoding];
    
    commandBuffer.label = @"DrawTextureCommandBuffer";
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures
    __autoreleasing MTLRenderPassDescriptor *renderPassDescriptor = [view currentRenderPassDescriptor];
    
    if(renderPassDescriptor != nil)
    {
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"DrawTextureRenderEncoder";
        
        // Set the region of the drawable to draw into.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];
        
        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                               atIndex:AAPLVertexInputIndexVertices];
        
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:AAPLVertexInputIndexViewportSize];
        
        // Set the texture object.  The AAPLTextureIndexBaseColor enum value corresponds
        ///  to the 'colorMap' argument in the 'samplingShader' function because its
        //   texture attribute qualifier also uses AAPLTextureIndexBaseColor for its index.
        [renderEncoder setFragmentTexture:computeTexture //view.currentDrawable.texture
                                  atIndex:AAPLTextureIndexBaseColor];
        
        // Draw the triangles.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];
        
        [renderEncoder endEncoding];
        
        // Schedule a present once the framebuffer is complete using the current drawable
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    _colorMap = create_texture(CMSampleBufferGetImageBuffer(sampleBuffer)); // before overwriting _colorMap, copy it to another texture (for differencing)
}

@end
