//
//  ControlView.h
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#ifndef ControlView_h
#define ControlView_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@import CoreHaptics;
@import QuartzCore;
@import CoreGraphics;

NS_ASSUME_NONNULL_BEGIN



static float (^degreesToRadians)(float) = ^ float (float degrees) {
    return (degrees * M_PI / 180.0);
};

static float (^ _Nonnull rescale)(float, float, float, float, float) = ^ float (float old_value, float old_min, float old_max, float new_min, float new_max) {
    float scaled_value = (new_max - new_min) * (old_value - old_min) / (old_max - old_min) + new_min;
//    printf("scaled_value == %f\n", scaled_value);
    return scaled_value;
};

typedef enum : NSUInteger {
    CaptureDeviceConfigurationControlPropertyTorchLevel,
    CaptureDeviceConfigurationControlPropertyLensPosition,
    CaptureDeviceConfigurationControlPropertyExposureDuration,
    CaptureDeviceConfigurationControlPropertyISO,
    CaptureDeviceConfigurationControlPropertyVideoZoomFactor,
    CaptureDeviceConfigurationControlPropertyAll
} CaptureDeviceConfigurationControlProperty;

static dispatch_queue_t _Nonnull enumerator_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("enumerator_queue()", NULL);
    });
    
    return queue;
};

#define BUTTON_ARC_COMPONENT_MASK  ( 1 << 0 |   1 << 1 |   1 << 2 |   1 << 3 |   1 << 4)
#define TICK_WHEEL_COMPONENT_MASK ( 0 << 0 |   0 << 1 |   0 << 2 |   0 << 3 |   0 << 4)


unsigned long active_component_bit_vector     = BUTTON_ARC_COMPONENT_MASK;
unsigned long highlighted_property_bit_vector = TICK_WHEEL_COMPONENT_MASK;
unsigned long selected_property_bit_vector    = TICK_WHEEL_COMPONENT_MASK;
unsigned long hidden_property_bit_vector      = TICK_WHEEL_COMPONENT_MASK;

@interface ControlView : UIView

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *highlightedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

#endif

NS_ASSUME_NONNULL_END
