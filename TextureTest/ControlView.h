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

@property (nonatomic) CGFloat videoZoomFactor;
- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor;


@end

@interface ControlView : UIView

@property (weak) IBOutlet id<CaptureDeviceConfigurationControlPropertyDelegate> captureDeviceConfigurationControlPropertyDelegate;

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;

@end

NS_ASSUME_NONNULL_END
