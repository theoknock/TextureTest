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

static float gaussian_mean = 0.5;
static float * gaussian_mean_t = &gaussian_mean;
static float standard_deviation = 6.0;
static float * standard_deviation_t = &standard_deviation;

@interface Renderer : NSObject <MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

@property (weak, nonatomic) IBOutlet UISlider *gaussianMeanSlider;
- (IBAction)gaussianMeanChanged:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UISlider *standardDeviationSlider;
- (IBAction)standardDeviationChanged:(id)sender;

@property (strong, nonatomic, readonly) id<MTLComputePipelineState> computePipelineState;
@property (nonatomic, readonly) MTLSize gridSize;
@property (nonatomic, readonly) MTLSize threadgroupsPerGrid;
@property (nonatomic, readonly) MTLSize threadsPerThreadgroup;

@end

