//
//  Renderer.h
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoCamera.h"
@import UIKit;

static float narrow_band_param[] = {0.5f, 1.f};
static typeof(narrow_band_param) * narrow_band_param_t = &narrow_band_param;

@interface Renderer : NSObject <MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
//- (IBAction)sliderValueChanged:(UISlider *)sender;

@property (weak, nonatomic) IBOutlet UISlider *gaussianMeanSlider;
@property (weak, nonatomic) IBOutlet UISlider *standardDeviationSlider;

@property (strong, nonatomic, readonly) id<MTLComputePipelineState> computePipelineState;
@property (nonatomic, readonly) MTLSize gridSize;
@property (nonatomic, readonly) MTLSize threadgroupsPerGrid;
@property (nonatomic, readonly) MTLSize threadsPerThreadgroup;

@end

