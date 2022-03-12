//
//  Renderer.h
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>

#import "VideoCamera.h"

static float (^degreesToRadians)(float) = ^ float (float degrees) {
    return (degrees * M_PI / 180.0);
};

static float (^ _Nonnull rescale)(float, float, float, float, float) = ^ float (float old_value, float old_min, float old_max, float new_min, float new_max) {
    float scaled_value = (new_max - new_min) * (old_value - old_min) / (old_max - old_min) + new_min;
//    printf("scaled_value == %f\n", scaled_value);
    return scaled_value;
};



// Our platform independent renderer class.   Implements the MTKViewDelegate protocol which
//   allows it to accept per-frame update and drawable resize callbacks.
@interface Renderer : NSObject <MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

@end

