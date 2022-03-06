//
//  ControlView.h
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@import CoreHaptics;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    CaptureDeviceConfigurationControlPropertyTorchLevel,
    CaptureDeviceConfigurationControlPropertyLensPosition,
    CaptureDeviceConfigurationControlPropertyExposureDuration,
    CaptureDeviceConfigurationControlPropertyISO,
    CaptureDeviceConfigurationControlPropertyVideoZoomFactor,
    CaptureDeviceConfigurationControlPropertyAll
} CaptureDeviceConfigurationControlProperty;

@protocol CaptureDeviceConfigurationControlPropertyDelegate <NSObject>
@required

- (float)maxISO_;
- (float)minISO_;
- (void)setCaptureDeviceConfigurationControlPropertyUsingBlock:(void(^)(AVCaptureDevice *))captureDeviceConfigurationControlPropertyBlock;
- (void)setCaptureDeviceConfigurationControlProperty:(CaptureDeviceConfigurationControlProperty)property value:(float)value;

@end

@interface ControlView : UIView


@property (strong) IBOutlet id<CaptureDeviceConfigurationControlPropertyDelegate> captureDeviceConfigurationControlPropertyDelegate;

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *highlightedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

NS_ASSUME_NONNULL_END
