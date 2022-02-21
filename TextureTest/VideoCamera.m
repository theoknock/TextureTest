//
//  Camera.m
//  AVDemonCamManualMetalII
//
//  Created by Xcode Developer on 1/14/22.
//

#import "VideoCamera.h"

CGSize videoDimensions;

@interface VideoCamera ()
{
    AVCaptureSession * captureSession;
//    AVCaptureDevice * captureDevice;
    AVCaptureDeviceInput * captureInput;
//    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureVideoDataOutput * captureOutput;
}

@end

@implementation VideoCamera

static AVCaptureDevice * _captureDevice;
+ (AVCaptureDevice *)captureDevice { return _captureDevice; }
+ (void)setCaptureDevice:(AVCaptureDevice *)captureDevice { _captureDevice = captureDevice; }


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
                    [captureOutput setDeliversPreviewSizedOutputBuffers:FALSE];
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
            }
        }
    }
    
    return self;
}

- (CGFloat)videoZoomFactor_ {
//    printf("videoZoomFactor == %f\n", VideoCamera.captureDevice.videoZoomFactor);
    return [(AVCaptureDevice *)VideoCamera.captureDevice videoZoomFactor];
}

- (void)setVideoZoomFactor_:(CGFloat)videoZoomFactor {
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
            [VideoCamera.captureDevice setVideoZoomFactor:videoZoomFactor];
        } @catch (NSException *exception) {
            NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
                  exception.name,
                  exception.reason,
                  ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
        } @finally {
            [VideoCamera.captureDevice unlockForConfiguration];
            [self videoZoomFactor_];
//            printf("setVideoZoomFactor == %f\n", videoZoomFactor);
        }
}

- (CGFloat)lensPosition_ {
//    printf("lensPosition_ == %f\n", VideoCamera.captureDevice.lensPosition);
    return [(AVCaptureDevice *)VideoCamera.captureDevice lensPosition];
}

- (void)setLensPosition_:(CGFloat)lensPosition {
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
        [VideoCamera.captureDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:nil];
    } @catch (NSException *exception) {
        NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
              exception.name,
              exception.reason,
              ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
    } @finally {
        [VideoCamera.captureDevice unlockForConfiguration];
        [self lensPosition_];
//        printf("lensPosition == %f\n", lensPosition);
    }
}

- (CGFloat)torchLevel_ {
    return [VideoCamera.captureDevice torchLevel];
}

- (void)setTorchLevel_:(CGFloat)torchLevel {
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
        if ([VideoCamera.captureDevice lockForConfiguration:&error] && ([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
            if (torchLevel != 0)
                [VideoCamera.captureDevice setTorchModeOnWithLevel:torchLevel error:&error];
            else
                [VideoCamera.captureDevice setTorchMode:AVCaptureTorchModeOff];
        }
    } @catch (NSException *exception) {
        NSLog(@"Error configuring camera:\n\t%@\n\t%@\n\t%lu",
              exception.name,
              exception.reason,
              ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
    } @finally {
        [VideoCamera.captureDevice unlockForConfiguration];
        [self lensPosition_];
//        printf("lensPosition == %f\n", lensPosition);
    }
}


@end
