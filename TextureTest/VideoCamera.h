//
//  Camera.h
//  AVDemonCamManualMetalII
//
//  Created by Xcode Developer on 1/14/22.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ControlView.h"

NS_ASSUME_NONNULL_BEGIN
extern dispatch_queue_t video_data_output_sample_buffer_delegate_queue;
extern CGSize videoDimensions;

@interface VideoCamera : NSObject <CaptureDeviceConfigurationControlPropertyDelegate>

+ (VideoCamera *)setAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)videoOutputDelegate;

- (float)maxISO_;
- (float)minISO_;
- (void)setCaptureDeviceConfigurationControlPropertyUsingBlock:(void(^)(AVCaptureDevice *))captureDeviceConfigurationControlPropertyBlock;

@property (class, nonatomic, strong, readwrite) AVCaptureDevice * captureDevice;

@end

NS_ASSUME_NONNULL_END
