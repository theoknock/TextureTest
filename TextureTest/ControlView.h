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
@required
@property (nonatomic) CGFloat videoZoomFactor_;
- (void)setVideoZoomFactor_:(CGFloat)videoZoomFactor;
@property (nonatomic) CGFloat lensPosition_;
- (void)setLensPosition_:(CGFloat)lensPosition;
@property (nonatomic) CGFloat torchLevel_;
- (void)setTorchLevel_:(CGFloat)torchLevel;
@property (nonatomic) CGFloat ISO_;
- (void)setISO_:(CGFloat)ISO;
- (float)maxISO_;
- (float)minISO_;
- (void)setExposureDuration_:(CGFloat)exposureDuration;





@end

@interface ControlView : UIView


@property (strong) IBOutlet id<CaptureDeviceConfigurationControlPropertyDelegate> captureDeviceConfigurationControlPropertyDelegate;

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

NS_ASSUME_NONNULL_END
