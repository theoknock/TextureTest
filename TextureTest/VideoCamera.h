//
//  Camera.h
//  AVDemonCamManualMetalII
//
//  Created by Xcode Developer on 1/14/22.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ControlView.h"
#import "Renderer.h"

NS_ASSUME_NONNULL_BEGIN


typedef enum : NSUInteger {
    CaptureDeviceConfigurationPhaseLock,
    CaptureDeviceConfigurationPhaseConfigure,
    CaptureDeviceConfigurationPhaseUnlock
} CaptureDeviceConfigurationPhase;



static const float kExposureDurationPower = 5.0;
static const float kExposureMinimumDuration = 1.0/1000;

extern dispatch_queue_t video_data_output_sample_buffer_delegate_queue;
extern CGSize videoDimensions;

@interface VideoCamera : NSObject <CaptureDeviceConfigurationControlPropertyDelegate>

+ (VideoCamera *)setAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)videoOutputDelegate;

- (float)maxISO_;
- (float)minISO_;
@property (class, strong, nonatomic, readonly) void(^captureDeviceConfigurationControlPropertyBlock)(CaptureDeviceConfigurationControlProperty, float, UITouchPhase);

@property (class, nonatomic, strong, readwrite) AVCaptureDevice * captureDevice;

@end

NS_ASSUME_NONNULL_END
