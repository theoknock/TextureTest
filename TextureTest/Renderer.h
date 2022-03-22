//
//  Renderer.h
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoCamera.h"

@interface Renderer : NSObject <MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

@property (strong, nonatomic, readonly) id<MTLComputePipelineState> computePipelineState;
@property (nonatomic, readonly) MTLSize gridSize;
@property (nonatomic, readonly) MTLSize threadgroupsPerGrid;
@property (nonatomic, readonly) MTLSize threadsPerThreadgroup;


@end

