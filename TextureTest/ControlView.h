//
//  ControlView.h
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import <UIKit/UIKit.h>
@import CoreHaptics;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    CaptureDeviceConfigurationControlPropertyTorchLevel,
    CaptureDeviceConfigurationControlPropertyLensPosition,
    CaptureDeviceConfigurationControlPropertyExposureDuration,
    CaptureDeviceConfigurationControlPropertyISO,
    CaptureDeviceConfigurationControlPropertyVideoZoomFactor
} CaptureDeviceConfigurationControlProperty;

@protocol CaptureDeviceConfigurationControlPropertyDelegate <NSObject>

@property (nonatomic) CGFloat videoZoomFactor_;
- (void)setVideoZoomFactor_:(CGFloat)videoZoomFactor;


@end

@interface ControlView : UIView


@property (strong) IBOutlet id<CaptureDeviceConfigurationControlPropertyDelegate> captureDeviceConfigurationControlPropertyDelegate;

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

NS_ASSUME_NONNULL_END
