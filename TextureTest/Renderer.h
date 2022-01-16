//
//  Renderer.h
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>

#import "VideoCamera.h"

#define degreesToRadians(angleDegrees) (angleDegrees * M_PI / 180.0)


// Our platform independent renderer class.   Implements the MTKViewDelegate protocol which
//   allows it to accept per-frame update and drawable resize callbacks.
@interface Renderer : NSObject <MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

@end

