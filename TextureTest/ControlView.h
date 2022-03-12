//
//  ControlView.h
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@import CoreHaptics;
@import QuartzCore;
@import CoreGraphics;

NS_ASSUME_NONNULL_BEGIN

@interface ControlLayer : CAGradientLayer

@end

NS_ASSUME_NONNULL_END

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
@end

static dispatch_queue_t enumerator_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("enumerator_queue()", NULL);
    });
    
    return queue;
};


@interface ControlView : UIView


@property (strong) IBOutlet id<CaptureDeviceConfigurationControlPropertyDelegate> captureDeviceConfigurationControlPropertyDelegate;

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *highlightedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

NS_ASSUME_NONNULL_END
