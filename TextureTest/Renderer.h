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

@end

