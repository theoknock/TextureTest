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

#include <stdatomic.h>
#include <libkern/OSAtomic.h>

NS_ASSUME_NONNULL_BEGIN

static const float kPi_f      = (float)(M_PI);
static const float k1Div180_f = 1.0f / 180.0f;
static const float kRadians_f = k1Div180_f * kPi_f;

static float (^degreesToRadians)(float) = ^ float (float degrees) {
    return (degrees * M_PI / 180.0);
};

static float (^ _Nonnull rescale)(float, float, float, float, float) = ^ float (float old_value, float old_min, float old_max, float new_min, float new_max) {
    float scaled_value = (new_max - new_min) * (old_value - old_min) / (old_max - old_min) + new_min;
    return scaled_value;
};

typedef enum : unsigned long {
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

#define BUTTON_ARC_COMPONENT_BIT_MASK ( 1UL << 0 |   1UL << 1 |   1UL << 2 |   1UL << 3 |   1UL << 4 )
#define TICK_WHEEL_COMPONENT_BIT_MASK ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 )
#define TRUE_BIT ( 1UL << 0 )
#define FALSE_BIT (TRUE_BIT ^ TRUE_BIT)

unsigned long active_component_bit_vector = ( 1UL << 0 |   1UL << 1 |   1UL << 2 |   1UL << 3 |   1UL << 4 );

//#define BUTTON_ARC_COMPONENT_ACTIVE ( active_component_bit_vector & BUTTON_ARC_COMPONENT_BIT_MASK )
//#define TICK_WHEEL_COMPONENT_ACTIVE ( active_component_bit_vector ^ BUTTON_ARC_COMPONENT_BIT_MASK )
//#define BUTTON_ARC_COMPONENT_INACTIVE ( active_component_bit_vector ^ BUTTON_ARC_COMPONENT_BIT_MASK )
//#define TICK_WHEEL_COMPONENT_INACTIVE ( active_component_bit_vector ^ TICK_WHEEL_COMPONENT_BIT_MASK )

unsigned long highlighted_property_bit_vector = ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 );
unsigned long selected_property_bit_vector    = ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 );
unsigned long hidden_property_bit_vector      = ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 );

@interface ControlView : UIView <UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate, UIDynamicItem>

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *highlightedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

#endif

NS_ASSUME_NONNULL_END
