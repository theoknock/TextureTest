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
#import <CoreText/CoreText.h>
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

static dispatch_queue_t _Nonnull animator_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
    });
    
    return queue;
};

#define BUTTON_ARC_COMPONENT_BIT_MASK ( 1UL << 0 |   1UL << 1 |   1UL << 2 |   1UL << 3 |   1UL << 4 )
#define TICK_WHEEL_COMPONENT_BIT_MASK ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 )
#define TRUE_BIT ( 1UL << 0 )
#define FALSE_BIT (TRUE_BIT ^ TRUE_BIT)

unsigned long active_component_bit_vector = ( 1UL << 0 |   1UL << 1 |   1UL << 2 |   1UL << 3 |   1UL << 4 );
// Tests whether the button arc is displayed by testing whether the tick wheel is not displayed:
//          (active_component_bit_vector ^ TICK_WHEEL_COMPONENT_BIT_MASK)

//#define BUTTON_ARC_COMPONENT_ACTIVE ( active_component_bit_vector & BUTTON_ARC_COMPONENT_BIT_MASK )
//#define TICK_WHEEL_COMPONENT_ACTIVE ( active_component_bit_vector ^ BUTTON_ARC_COMPONENT_BIT_MASK )
//#define BUTTON_ARC_COMPONENT_INACTIVE ( active_component_bit_vector ^ BUTTON_ARC_COMPONENT_BIT_MASK )
//#define TICK_WHEEL_COMPONENT_INACTIVE ( active_component_bit_vector ^ TICK_WHEEL_COMPONENT_BIT_MASK )

unsigned long highlighted_property_bit_vector = ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 );
unsigned long selected_property_bit_vector    = ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 );
unsigned long hidden_property_bit_vector      = ( 0UL << 0 |   0UL << 1 |   0UL << 2 |   0UL << 3 |   0UL << 4 );

/*
 
 Building blocks of predicated invocation and task modularization and sequencing
 
 */

// A conditional block that is an aggregate of boolean expressions, evaluated in succession by the functors in the chain the block traverses
// It does not "return" until its functor(s) have returned (this ensures that any conditions it manages to remain within its purview before it passes its logic to the next block in the chain
// It wraps around a functor (a functional unit or series of related tasks), and is invoked first and last
// Every functor takes this block and returns this block -- and that only
// It is used to determine whether its functor should be invoked and whether it should invoke the next
// It passes other decision-making logic to the next block
// It is the point on a path of execution in a chain of blocks
// How a functor uses a conditional block:
//      - on receiving, evaluate the aggregate of expressions to determine whether to invoke a functor(s)
//      - use the expressions during the course of functor execution
//      - add the evaluation (the results of the expressions it contained when received) of the expressions
//        for use as expressions by other functors

typedef typeof(const unsigned long(^)(const unsigned long)) predicate_blk_ref;

predicate_blk_ref predicate_blk = ^ const unsigned long (const unsigned long predicate) {
    return predicate;
};

const void * (^ const __strong predicate_blk_t)(predicate_blk_ref) = ^ (predicate_blk_ref blk_ref) {
    return Block_copy((const void *)CFBridgingRetain(blk_ref));
};

unsigned long (^(^evaluate_predicate_blk)(const unsigned long))(const void * _Nonnull) = ^ (const unsigned long predicate) {
return ^ (const void * predicate_expr) {
    return ((typeof(const unsigned long (^)(const unsigned long)))CFBridgingRelease(predicate_expr))(predicate);
    };
};


/*
 
 */

typedef typeof(const unsigned long (^)(void)) predicate_blk_x_ref;

predicate_blk_x_ref (^ const __strong predicate_blk_x)(unsigned long) = ^ (unsigned long predicate) {
    return ^ const unsigned long {
        return predicate;
    };
};

const void * (^ const __strong predicate_blk_x_t)(predicate_blk_x_ref) = ^ (predicate_blk_x_ref blk_x_ref) {
    return Block_copy((const void *)CFBridgingRetain(blk_x_ref));
};

//predicate_blk_x_ref p_ref = predicate_blk_x(touch_property);

//const void * predicate_blk_ptr_x = predicate_blk_ref_t(p_ref);
unsigned long (^evaluate_predicate_blk_x)(const void * _Nonnull) = ^ (const void * predicate_expr) {
    return ((typeof(const unsigned long (^)(void)))CFBridgingRelease(predicate_expr))();
};

/* A block that invokes a nested block that is not required to return a value
   (e.g., to return a predicate expression that determines — in conjunction with other expressions –
 whether the nested block should be invoked; usually it is the last inner block that is required to supply a return value and,
 in all cases, any block that returns the defined type must execute completely before it can do so.
 */

//unsigned long (^(^predicate_function_blk)(predicate_blk_ref))(unsigned long)  = ^ (predicate_blk_ref predicate_blk) {
//    return ^ (unsigned long(^bit_operation)(unsigned long)) {
//        return (^{
//            printf("\n%lu%lu%lu%lu%lu\n",
//                   bit_operation((x >> 0) & 1UL),
//                   bit_operation((x >> 1) & 1UL),
//                   bit_operation((x >> 2) & 1UL),
//                   bit_operation((x >> 3) & 1UL),
//                   bit_operation((x >> 4) & 1UL));
//            return ^{
//                return bit_operation;
//            };
//        }()());
//    }(^ unsigned long (unsigned long bit) {
//        return bit;
//    });
//};



@interface ControlView : UIView <UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate, UIDynamicItem>

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *highlightedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

#endif

NS_ASSUME_NONNULL_END
