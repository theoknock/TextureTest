//
//  Camera.m
//  AVDemonCamManualMetalII
//
//  Created by Xcode Developer on 1/14/22.
//

#import "VideoCamera.h"



@implementation VideoCamera
{
    CGSize videoDimensions;
    AVCaptureSession * captureSession;
//    AVCaptureDevice * captureDevice;
    AVCaptureDeviceInput * captureInput;
    //    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureVideoDataOutput * captureOutput;
}

static AVCaptureDevice * _captureDevice;
+ (AVCaptureDevice *)captureDevice { return _captureDevice; }
+ (void)setCaptureDevice:(AVCaptureDevice *)captureDevice { _captureDevice = captureDevice; }

static void (^(^set_configuration_phase)(UITouchPhase))(void(^)(void)) = ^ (UITouchPhase phase) {
    //    printf("\t\tphase == %ld\n", (long)phase);
    switch (phase) {
        case UITouchPhaseBegan: {
            return ^ (void(^configuration)(void)) {
                @try {
                    __autoreleasing NSError *error = NULL;
                    [VideoCamera.captureDevice lockForConfiguration:&error];
                    if (error) {
                        printf("Error == %s\n", [[error debugDescription] UTF8String]);
                        NSException* exception = [NSException
                                                  exceptionWithName:error.domain
                                                  reason:error.localizedDescription
                                                  userInfo:@{@"Error Code" : @(error.code)}];
                        @throw exception;
                    }
                } @catch (NSException *exception) {
                    NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
                          exception.name,
                          exception.reason,
                          ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
                } @finally {
                    configuration();
                }
            };
            break;
        }
        case UITouchPhaseEnded: {
            return ^ (void(^configuration)(void)) {
                configuration();
                [VideoCamera.captureDevice unlockForConfiguration];
                
            };
            break;
        }
        case UITouchPhaseMoved: {
            return ^ (void(^configuration)(void)) {
                configuration();
                
            };
            break;
        }
        default: {
            return ^ (void(^configuration)(void)) {
                //                printf("UITouchPhase == %u\n", phase);
            };
            break;
        }
    }
};

//+ (long(^)(CaptureDeviceConfigurationControlProperty, float, UITouchPhase))captureDeviceConfigurationControlPropertyBlock { return captureDeviceConfigurationControlPropertyBlock_; }
//static long(^captureDeviceConfigurationControlPropertyBlock_)(CaptureDeviceConfigurationControlProperty, float, UITouchPhase) = ^ (CaptureDeviceConfigurationControlProperty property, float value, UITouchPhase phase) {
//    dispatch_barrier_sync(enumerator_queue(), ^{
//        switch (property) {
//            case CaptureDeviceConfigurationControlPropertyTorchLevel: {
//                ^ (CGFloat torchLevel, void(^configure_phase)(void(^)(void))) {
//                    configure_phase(^{
//                        __autoreleasing NSError * error = nil;
//                        if (([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
//                            if (torchLevel != 0)
//                                [VideoCamera.captureDevice setTorchModeOnWithLevel:torchLevel error:&error];
//                            else
//                                [VideoCamera.captureDevice setTorchMode:AVCaptureTorchModeOff];
//                        }
//                    });
//                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                break;
//            }
//            case CaptureDeviceConfigurationControlPropertyLensPosition: {
//                ^ (CGFloat lensPosition, void(^configure_phase)(void(^)(void))) {
//                    configure_phase(^{
//                        [VideoCamera.captureDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:nil];
//                    });
//                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                break;
//            }
//            case CaptureDeviceConfigurationControlPropertyExposureDuration: {
//                ^ (CGFloat exposureDuration, void(^configure_phase)(void(^)(void))) {
//                    configure_phase(^{
//                        double p = pow( exposureDuration, kExposureDurationPower ); // Apply power function to expand slider's low-end range
//                        double minDurationSeconds = MAX( CMTimeGetSeconds(VideoCamera.captureDevice.activeFormat.minExposureDuration ), kExposureMinimumDuration );
//                        double maxDurationSeconds = 1.0/3.0;//CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
//                        double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
//                        [VideoCamera.captureDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
//                    });
//                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                break;
//            }
//            case CaptureDeviceConfigurationControlPropertyISO: {
//                ^ (CGFloat ISO, void(^configure_phase)(void(^)(void))) {
//                    configure_phase(^{
//                        @try {
//                            [VideoCamera.captureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:nil];
//                        } @catch (NSException *exception) {
//                            [VideoCamera.captureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:AVCaptureISOCurrent completionHandler:nil];
//                        } @finally {
//                            
//                        }
//                        
//                    });
//                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                break;
//            }
//            case CaptureDeviceConfigurationControlPropertyVideoZoomFactor: {
//                ^ (CGFloat videoZoomFactor, void(^configure_phase)(void(^)(void))) {
//                    configure_phase(^{
//                        [VideoCamera.captureDevice setVideoZoomFactor:videoZoomFactor];
//                    });
//                }(rescale(value, 180.0, 270.0, 1.0, 9.0), set_configuration_phase(phase));
//                break;
//            }
//            default:
//                break;
//        }
//    });
//    return (long)1;
//};


static VideoCamera * video;
+ (VideoCamera *)setAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)videoOutputDelegate
{
    if (!video || video == nil)
    {
        video = [[self alloc] initWithAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)videoOutputDelegate];
    }
    
    return video;
}
dispatch_queue_t video_data_output_sample_buffer_delegate_queue;

- (instancetype)initWithAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)videoOutputDelegate
{
    if (self = [super init])
    {
        video_data_output_sample_buffer_delegate_queue = dispatch_queue_create("CVPixelBufferDispatchQueue", DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
        if (!captureSession) {
            @try {
                captureSession = [[AVCaptureSession alloc] init];
                [captureSession beginConfiguration];
                if ([captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
                    [captureSession setSessionPreset:AVCaptureSessionPreset3840x2160];
                }
                
                VideoCamera.captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
                @try {
                    __autoreleasing NSError *error = NULL;
                    [VideoCamera.captureDevice lockForConfiguration:&error];
                    if (error) {
                        NSException* exception = [NSException
                                                  exceptionWithName:error.domain
                                                  reason:error.localizedDescription
                                                  userInfo:@{@"Error Code" : @(error.code)}];
                        @throw exception;
                    }
                    if ([VideoCamera.captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                        [VideoCamera.captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                    if ([VideoCamera.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
                        [VideoCamera.captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                    [VideoCamera.captureDevice setVideoZoomFactor:VideoCamera.captureDevice.minAvailableVideoZoomFactor];
                } @catch (NSException *exception) {
                    NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
                          exception.name,
                          exception.reason,
                          ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
                } @finally {
                    [VideoCamera.captureDevice unlockForConfiguration];
                }
                
                __autoreleasing NSError * error;
                captureInput = [AVCaptureDeviceInput deviceInputWithDevice:VideoCamera.captureDevice error:&error];
                if ([captureSession canAddInput:captureInput])
                    [captureSession addInput:captureInput];
                
                captureOutput = [[AVCaptureVideoDataOutput alloc] init];
                [captureOutput setAlwaysDiscardsLateVideoFrames:TRUE];
                [captureOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
                [captureOutput setSampleBufferDelegate:videoOutputDelegate queue:video_data_output_sample_buffer_delegate_queue];
                
                if ([captureSession canAddOutput:captureOutput])
                    [captureSession addOutput:captureOutput];
                
                //            AVCaptureVideoOrientation __block preferredVideoOrientation = AVCaptureVideoOrientationPortrait;
                //            UIInterfaceOrientation interfaceOrientation = [[[[UIApplication sharedApplication] windows] firstObject] windowScene].interfaceOrientation;
                //            if (interfaceOrientation != UIInterfaceOrientationUnknown ) {
                //                preferredVideoOrientation = (AVCaptureVideoOrientation)interfaceOrientation;
                //            }
                //            previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
                //            previewLayer.session = captureSession;
                //            previewLayer.connection.videoOrientation = preferredVideoOrientation;
                
                AVCaptureConnection *videoDataCaptureConnection = [[AVCaptureConnection alloc] initWithInputPorts:captureInput.ports output:captureOutput];
                if ([videoDataCaptureConnection isVideoOrientationSupported])
                {
                    [captureOutput setAutomaticallyConfiguresOutputBufferDimensions:FALSE];
                    [captureOutput setDeliversPreviewSizedOutputBuffers:TRUE];
                    [videoDataCaptureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                    [videoDataCaptureConnection setVideoScaleAndCropFactor:1.0];
                }
                
                if ([captureSession canAddConnection:videoDataCaptureConnection])
                    [captureSession addConnection:videoDataCaptureConnection];
                
                [captureSession commitConfiguration];
                
                [captureSession startRunning];
                
            } @catch (NSException *exception) {
                NSLog(@"Camera setup error: %@", exception.description);
            } @finally {
                videoDimensions = CMVideoFormatDescriptionGetPresentationDimensions(VideoCamera.captureDevice.activeFormat.formatDescription, TRUE, FALSE);
//                self.captureDeviceConfigurationControlPropertyBlock = ^ (CaptureDeviceConfigurationControlProperty property, float value, UITouchPhase phase) {
//                    dispatch_barrier_sync(enumerator_queue(), ^{
//                        switch (property) {
//                            case CaptureDeviceConfigurationControlPropertyTorchLevel: {
//                                ^ (CGFloat torchLevel, void(^configure_phase)(void(^)(void))) {
//                                    configure_phase(^{
//                                        __autoreleasing NSError * error = nil;
//                                        if (([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
//                                            if (torchLevel != 0)
//                                                [VideoCamera.captureDevice setTorchModeOnWithLevel:torchLevel error:&error];
//                                            else
//                                                [VideoCamera.captureDevice setTorchMode:AVCaptureTorchModeOff];
//                                        }
//                                    });
//                                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                                break;
//                            }
//                            case CaptureDeviceConfigurationControlPropertyLensPosition: {
//                                ^ (CGFloat lensPosition, void(^configure_phase)(void(^)(void))) {
//                                    configure_phase(^{
//                                        [VideoCamera.captureDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:nil];
//                                    });
//                                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                                break;
//                            }
//                            case CaptureDeviceConfigurationControlPropertyExposureDuration: {
//                                ^ (CGFloat exposureDuration, void(^configure_phase)(void(^)(void))) {
//                                    configure_phase(^{
//                                        double p = pow( exposureDuration, kExposureDurationPower ); // Apply power function to expand slider's low-end range
//                                        double minDurationSeconds = MAX( CMTimeGetSeconds(VideoCamera.captureDevice.activeFormat.minExposureDuration ), kExposureMinimumDuration );
//                                        double maxDurationSeconds = 1.0/3.0;//CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
//                                        double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
//                                        [VideoCamera.captureDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
//                                    });
//                                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                                break;
//                            }
//                            case CaptureDeviceConfigurationControlPropertyISO: {
//                                ^ (CGFloat ISO, void(^configure_phase)(void(^)(void))) {
//                                    configure_phase(^{
//                                        @try {
//                                            [VideoCamera.captureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:nil];
//                                        } @catch (NSException *exception) {
//                                            [VideoCamera.captureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:AVCaptureISOCurrent completionHandler:nil];
//                                        } @finally {
//
//                                        }
//
//                                    });
//                                }(rescale(value, 180.0, 270.0, 0.0, 1.0), set_configuration_phase(phase));
//                                break;
//                            }
//                            case CaptureDeviceConfigurationControlPropertyVideoZoomFactor: {
//                                ^ (CGFloat videoZoomFactor, void(^configure_phase)(void(^)(void))) {
//                                    configure_phase(^{
//                                        [VideoCamera.captureDevice setVideoZoomFactor:videoZoomFactor];
//                                    });
//                                }(rescale(value, 180.0, 270.0, 1.0, 9.0), set_configuration_phase(phase));
//                                break;
//                            }
//                            default:
//                                break;
//                        }
//                    });
//                };
            }
        }
    }
    
    return self;
}

- (void)setCaptureDeviceConfigurationControlPropertyUsingBlock:(void(^)(AVCaptureDevice *))captureDeviceConfigurationControlPropertyBlock {
    @try {
        __autoreleasing NSError *error = NULL;
        [VideoCamera.captureDevice lockForConfiguration:&error];
        if (error) {
            printf("Error == %s\n", [[error debugDescription] UTF8String]);
            NSException* exception = [NSException
                                      exceptionWithName:error.domain
                                      reason:error.localizedDescription
                                      userInfo:@{@"Error Code" : @(error.code)}];
            @throw exception;
        }
        captureDeviceConfigurationControlPropertyBlock(VideoCamera.captureDevice);
    } @catch (NSException *exception) {
        NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
              exception.name,
              exception.reason,
              ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
    } @finally {
        [VideoCamera.captureDevice unlockForConfiguration];
    }
};

static void (^unlock_for_configuration)(void(^)(void)) = ^ (void(^captureDeviceConfigurationControlPropertyBlock)(void)) {
    @try {
        __autoreleasing NSError *error = NULL;
        [VideoCamera.captureDevice lockForConfiguration:&error];
        if (error) {
            printf("Error == %s\n", [[error debugDescription] UTF8String]);
            NSException* exception = [NSException
                                      exceptionWithName:error.domain
                                      reason:error.localizedDescription
                                      userInfo:@{@"Error Code" : @(error.code)}];
            @throw exception;
        }
        
    } @catch (NSException *exception) {
        NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
              exception.name,
              exception.reason,
              ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
    } @finally {
        
    }
};

static void(^set_capture_device_configuration_control_property)(void(^)(void)) = ^ (void(^captureDeviceConfigurationControlPropertyBlock)(void)) {
    @try {
        __autoreleasing NSError *error = NULL;
        [VideoCamera.captureDevice lockForConfiguration:&error];
        if (error) {
            printf("Error == %s\n", [[error debugDescription] UTF8String]);
            NSException* exception = [NSException
                                      exceptionWithName:error.domain
                                      reason:error.localizedDescription
                                      userInfo:@{@"Error Code" : @(error.code)}];
            @throw exception;
        }
        captureDeviceConfigurationControlPropertyBlock();
    } @catch (NSException *exception) {
        NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
              exception.name,
              exception.reason,
              ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
    } @finally {
        [VideoCamera.captureDevice unlockForConfiguration];
    }
};





@end
