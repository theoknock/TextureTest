//
//  ControlView.m
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import "ControlView.h"
#import "Renderer.h"
#include <simd/simd.h>
#import <objc/runtime.h>
#include <simd/simd.h>
#include <stdio.h>
#include <math.h>
@import Accelerate;
@import CoreHaptics;

static NSArray<NSString *> * const CaptureDeviceConfigurationControlPropertyImageKeys = @[@"CaptureDeviceConfigurationControlPropertyTorchLevel",
                                                                                          @"CaptureDeviceConfigurationControlPropertyLensPosition",
                                                                                          @"CaptureDeviceConfigurationControlPropertyExposureDuration",
                                                                                          @"CaptureDeviceConfigurationControlPropertyISO",
                                                                                          @"CaptureDeviceConfigurationControlPropertyZoomFactor"];


static NSArray<NSArray<NSString *> *> * const CaptureDeviceConfigurationControlPropertyImageValues = @[@[@"bolt.circle",
                                                                                                         @"viewfinder.circle",
                                                                                                         @"timer",
                                                                                                         @"camera.aperture",
                                                                                                         @"magnifyingglass.circle"],@[@"bolt.circle.fill",
                                                                                                                                      @"viewfinder.circle.fill",
                                                                                                                                      @"timer",
                                                                                                                                      @"camera.aperture",
                                                                                                                                      @"magnifyingglass.circle.fill"]];

typedef enum : NSUInteger {
    CaptureDeviceConfigurationControlStateDeselected,
    CaptureDeviceConfigurationControlStateSelected,
    CaptureDeviceConfigurationControlStateHighlighted
} CaptureDeviceConfigurationControlState;

static UIImageSymbolConfiguration * (^CaptureDeviceConfigurationControlPropertySymbolImageConfiguration)(CaptureDeviceConfigurationControlState) = ^ UIImageSymbolConfiguration * (CaptureDeviceConfigurationControlState state) {
    UIImageSymbolConfiguration * symbol_point_size_weight = [UIImageSymbolConfiguration configurationWithPointSize:42.0 weight:UIImageSymbolWeightUltraLight];
    switch (state) {
        case CaptureDeviceConfigurationControlStateDeselected: {
            UIImageSymbolConfiguration * symbol_color             = [UIImageSymbolConfiguration configurationWithHierarchicalColor:[UIColor systemIndigoColor]];
            return [symbol_color configurationByApplyingConfiguration:symbol_point_size_weight];
        }
            break;
        case CaptureDeviceConfigurationControlStateSelected: {
            UIImageSymbolConfiguration * symbol_color             = [UIImageSymbolConfiguration configurationWithHierarchicalColor:[UIColor systemYellowColor]];
            return [symbol_color configurationByApplyingConfiguration:symbol_point_size_weight];
        }
            break;
        case CaptureDeviceConfigurationControlStateHighlighted: {
            UIImageSymbolConfiguration * symbol_color             = [UIImageSymbolConfiguration configurationWithHierarchicalColor:[UIColor systemRedColor]];
            return [symbol_color configurationByApplyingConfiguration:symbol_point_size_weight];
        }
            break;
        default: {
            UIImageSymbolConfiguration * symbol_color             = [UIImageSymbolConfiguration configurationWithHierarchicalColor:[UIColor systemYellowColor]];
            return [symbol_color configurationByApplyingConfiguration:symbol_point_size_weight];
        }
            break;
    }
};

static NSString * (^CaptureDeviceConfigurationControlPropertySymbol)(CaptureDeviceConfigurationControlProperty, CaptureDeviceConfigurationControlState) = ^ NSString * (CaptureDeviceConfigurationControlProperty property, CaptureDeviceConfigurationControlState state) {
    return CaptureDeviceConfigurationControlPropertyImageValues[state][property];
};

static NSString * (^CaptureDeviceConfigurationControlPropertyString)(CaptureDeviceConfigurationControlProperty) = ^ NSString * (CaptureDeviceConfigurationControlProperty property) {
    return CaptureDeviceConfigurationControlPropertyImageKeys[property];
};

static UIImage * (^CaptureDeviceConfigurationControlPropertySymbolImage)(CaptureDeviceConfigurationControlProperty, CaptureDeviceConfigurationControlState) = ^ UIImage * (CaptureDeviceConfigurationControlProperty property, CaptureDeviceConfigurationControlState state) {
    return [UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertySymbol(property, state) withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(state)];
};

#define MASK_ALL  (1UL << 0 | 1UL << 1 | 1UL << 2 | 1UL << 3 | 1UL << 4)
#define MASK_NONE (  0 << 0 |   0 << 1 |   0 << 2 |   0 << 3 |   0 << 4)
static  uint8_t active_component_bit_vector  = MASK_ALL;
static  uint8_t selected_property_bit_vector = MASK_NONE;
static  uint8_t hidden_property_bit_vector   = MASK_NONE;

void(^set_state)(unsigned int) = ^ (unsigned int touch_property) {
    active_component_bit_vector = ~active_component_bit_vector;
    // Converse nonimplication: determines the selection state of the buttons
    uint8_t selected_property_bit_mask = MASK_NONE;
    selected_property_bit_mask ^= (1UL << touch_property) & ~active_component_bit_vector;
    selected_property_bit_vector = (selected_property_bit_vector | selected_property_bit_mask) & ~selected_property_bit_vector;
    // : determines the hidden state of the buttons
    hidden_property_bit_vector = ~active_component_bit_vector;
    hidden_property_bit_vector = selected_property_bit_mask & ~active_component_bit_vector;
    hidden_property_bit_vector ^= MASK_ALL;
    hidden_property_bit_vector ^= active_component_bit_vector;
};

static __strong UIButton * _Nonnull buttons[5];
static void (^(^map)(__strong UIButton * _Nonnull [_Nonnull 5]))(UIButton * (^__strong)(unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    dispatch_queue_t enumerator_queue  = dispatch_queue_create("enumerator_queue", DISPATCH_QUEUE_SERIAL);
    return ^ (UIButton *(^enumeration)(unsigned int)) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            dispatch_apply(5, enumerator_queue, ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    button_collection[index] = enumeration((unsigned int)index);
                });
            });
        });
    };
};

static long (^(^reduce)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    dispatch_queue_t enumerator_queue  = dispatch_queue_create("enumerator_queue", DISPATCH_QUEUE_SERIAL);
    return ^ (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            dispatch_apply(5, enumerator_queue, ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    ((selected_property_bit_vector >> index) & 1UL) ?: enumeration(button_collection[index], (unsigned int)index);
                });
            });
        });
        return (long)1;
    };
};


static long (^(^filter)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    dispatch_queue_t enumerator_queue  = dispatch_queue_create("enumerator_queue", DISPATCH_QUEUE_SERIAL);
    return ^ (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            dispatch_apply(5, enumerator_queue, ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    [button_collection[index] setSelected:(selected_property_bit_vector >> index) & 1UL];
                    [button_collection[index] setHidden:(hidden_property_bit_vector >> index) & 1UL];
                    enumeration(button_collection[index], (unsigned int)index);
                });
            });
        });
        return (long)1;
    };
};

static void (^(^touch_handler)(UITouch *))(void(^ _Nullable)(unsigned int));
static void (^handle_touch)(void(^ _Nullable)(unsigned int));
static void (^(^(^touch_handler_init)(ControlView *))(UITouch *))(void(^ _Nullable)(unsigned int)) =  ^ (ControlView * view) {
    CGRect contextRect = view.bounds;
    float midX = (float)CGRectGetMidX(contextRect) + [buttons[2] frame].size.width;
    float maxX = (float)CGRectGetMaxX(contextRect) - [buttons[4] frame].size.width;
    float maxY = (float)CGRectGetMaxY(contextRect) - [buttons[0] frame].size.width;
    simd_float2 center_point_simd = simd_make_float2(maxX, maxY);
    
    return ^ (UITouch * touch) {
        static CGPoint touch_point;
        
        
//        static CGFloat touch_angle;
        return ^ (void(^ _Nullable set_button_state)(unsigned int)) {
            touch_point = [touch preciseLocationInView:view];
            simd_float2 touch_point_simd = simd_make_float2(touch_point.x, touch_point.y);
            
//            touch_angle = (atan2(touch_point.y - maxY, touch_point.x - maxX) * (180.0 / M_PI)) + 360.0;
            simd_double2 touch_angle = _simd_atan2_d2(touch_point.y - maxY, touch_point.x - maxX)* (180.0 / M_PI) + 360.0;
            unsigned int touch_property = (unsigned int)round(rescale(touch_angle.x, 270.0, 180.0, 0.0, 4.0));
            if (set_button_state != nil) set_button_state(touch_property);
            // To-Do: Set tick wheel to actual selected camera property
            (((active_component_bit_vector >> 0) & 1UL) & reduce(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                printf("Reduce...\n");
                // To-Do: If touch phase is UITouchPhaseBegan, then set the selected button center to the normalized_video_zoom_factor
                [UIView animateWithDuration:(!(UITouchPhaseEnded ^ touch.phase) & 1UL) animations:^{
                    [button setCenter:^ (CGFloat radius, CGFloat angle) {
                        printf("angle == %f\n", angle);
                        ((active_component_bit_vector >> 1) & 0) ?: [(ControlView *)view setPropertyValue:angle];
                        CGFloat radians = degreesToRadians(angle);
                        return CGPointMake(maxX - radius * -cos(radians), maxY - radius * -sin(radians));
                    }(^ CGFloat (CGPoint endpoint) {
                        ((active_component_bit_vector >> 1) & 0) ?: [(ControlView *)view setRadius:fmaxf(midX, fminf(simd_distance(touch_point_simd, center_point_simd), maxX))];
                        return fmaxf(midX, fminf(simd_distance(touch_point_simd, center_point_simd), maxX));
                    }(button.center),  // find the center coordinate for the current video zoom factor
                      (((UITouchPhaseBegan ^ touch.phase) & 1UL) ? 0.0 /*rescale([[(ControlView *)view captureDeviceConfigurationControlPropertyDelegate] videoZoomFactor], 0.0, 1.0, 180.0, 270.0)*/ : 0.0 /*touch_angle.x*/))];
                }];
            })) | (~((active_component_bit_vector >> 0) & 1UL) & filter(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [UIView animateWithDuration:(!(UITouchPhaseEnded ^ touch.phase) & 1UL) animations:^{
                    printf("Filter...\n");
                    [button setHighlighted:((active_component_bit_vector >> button.tag) & 1UL) & (UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                    [button setCenter:^ (CGFloat radius, CGFloat angle) {
                        ((active_component_bit_vector >> 1) & 0) ?: [(ControlView *)view setPropertyValue:touch_angle.x];
                        CGFloat radians = degreesToRadians(angle);
                        return CGPointMake(maxX - radius * -cos(radians), maxY - radius * -sin(radians));
                    }(^ CGFloat (CGPoint endpoint) {
                        ((active_component_bit_vector >> 1) & 0) ?: [(ControlView *)view setRadius:fmaxf(midX, fminf(simd_distance(touch_point_simd, center_point_simd), maxX))];
                        return fmaxf(midX, fminf(simd_distance(touch_point_simd, center_point_simd), maxX));
                    }((((active_component_bit_vector >> button.tag) & 1UL) ? touch_point : button.center)),
                      ((active_component_bit_vector >> button.tag) & 1UL) ? ((NSNumber *)(objc_getAssociatedObject(button, (void *)button.tag))).floatValue : touch_angle.x)];
                }];
            }));
            
            filter(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [UIView animateWithDuration:(!(UITouchPhaseEnded ^ touch.phase) & 1UL) animations:^{
                    [button setHighlighted:((active_component_bit_vector >> button.tag) & 1UL) & (UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                    [button setCenter:^ (CGFloat radius, CGFloat angle) {
                        ((active_component_bit_vector >> 1) & 0) ?: [(ControlView *)view setPropertyValue:touch_angle.x];
                        CGFloat radians = degreesToRadians(angle);
                        return CGPointMake(maxX - radius * -cos(radians), maxY - radius * -sin(radians));
                    }(^ CGFloat (CGPoint endpoint) {
                        ((active_component_bit_vector >> 1) & 0) ?: [(ControlView *)view setRadius:fmaxf(midX, fminf(simd_distance(touch_point_simd, center_point_simd), maxX))];
                        return fmaxf(midX, fminf(simd_distance(touch_point_simd, center_point_simd), maxX));
                    }((((active_component_bit_vector >> button.tag) & 1UL) ? touch_point : button.center)),
                      ((active_component_bit_vector >> button.tag) & 1UL) ? ((NSNumber *)(objc_getAssociatedObject(button, (void *)button.tag))).floatValue : touch_angle.x)];
                }];
            });
            
            [(ControlView *)view setNeedsDisplay];
        };
    };
};

@implementation ControlView {
    UISelectionFeedbackGenerator * haptic_feedback;
    NSDictionary* hapticDict;
}

@synthesize radius, propertyValue;

- (void)setRadius:(CGFloat)radius {
    self->radius = radius;
}

- (CGFloat)radius {
    return (self->radius < CGRectGetMidX(self.bounds) ? CGRectGetMidX(self.bounds) : self->radius);
}

- (void)setPropertyValue:(CGFloat)propertyValue {
    if (round(propertyValue) != round(self->propertyValue)) {
        [haptic_feedback selectionChanged];
        [haptic_feedback prepare];
//        printf("property_value_angle = %f\n", self->propertyValue);
        self->propertyValue = (propertyValue != 0.0) ? propertyValue : self->propertyValue;
    }
    
}

- (CGFloat)propertyValue {
    return self->propertyValue;
}



- (void)awakeFromNib {
    [super awakeFromNib];

    
//    self.supportsHaptics = CHHapticEngine.capabilitiesForHardware.supportsHaptics;
//    printf("CHHapticEngine %s\n", (self.supportsHaptics) ? "supported" : "not supported");
//    __autoreleasing NSError* error = nil;
//    _engine = [[CHHapticEngine alloc] initAndReturnError:&error];
//    printf("%s\n", (error) ? [error.localizedDescription UTF8String] : "Initialized CHHapticEngine");
//    hapticDict =
//        @{
//         CHHapticPatternKeyPattern:
//               @[ // Start of array
//                 @{  // Start of first dictionary entry in the array
//                     CHHapticPatternKeyEvent: @{ // Start of first item
//                             CHHapticPatternKeyEventType:CHHapticEventTypeHapticTransient,
//                             CHHapticPatternKeyTime:@0.5,
//                             CHHapticPatternKeyEventDuration:@1.0
//                             },  // End of first item
//                   }, // End of first dictionary entry in the array
//                ], // End of array
//         }; // End of haptic dictionary
//
//    CHHapticPattern* pattern = [[CHHapticPattern alloc] initWithDictionary:hapticDict error:&error];
//    _player = [_engine createPlayerWithPattern:pattern error:&error];
//    __weak ControlView * w_control_view = self;
//    [_engine setResetHandler:^{
//        NSLog(@"Engine RESET!");
//        // Try restarting the engine again.
//        __autoreleasing NSError* error = nil;
//        [w_control_view.engine startAndReturnError:&error];
//        if (error) {
//            NSLog(@"ERROR: Engine couldn't restart!");
//        }
//        _player = [_engine createPlayerWithPattern:pattern error:&error];
//    }];
//    [_engine setStoppedHandler:^(CHHapticEngineStoppedReason reason){
//        NSLog(@"Engine STOPPED!");
//        switch (reason)
//        {
//            case CHHapticEngineStoppedReasonAudioSessionInterrupt: {
//                NSLog(@"REASON: Audio Session Interrupt");
//                // A phone call or notification could have come in, so take note to restart the haptic engine after the call ends. Wait for user-initiated playback.
//                break;
//            }
//            case CHHapticEngineStoppedReasonApplicationSuspended: {
//                NSLog(@"REASON: Application Suspended");
//                // The user could have backgrounded your app, so take note to restart the haptic engine when the app reenters the foreground. Wait for user-initiated playback.
//                break;
//            }
//            case CHHapticEngineStoppedReasonIdleTimeout: {
//                NSLog(@"REASON: Idle Timeout");
//                // The system stopped an idle haptic engine to conserve power, so restart it before your app must play the next haptic pattern.
//                break;
//            }
//            case CHHapticEngineStoppedReasonNotifyWhenFinished: {
//                printf("CHHapticEngineStoppedReasonNotifyWhenFinished\n");
//                break;
//            }
//            case CHHapticEngineStoppedReasonEngineDestroyed: {
//                printf("CHHapticEngineStoppedReasonEngineDestroyed\n");
//                break;
//            }
//            case CHHapticEngineStoppedReasonGameControllerDisconnect: {
//                printf("CHHapticEngineStoppedReasonGameControllerDisconnect\n");
//                break;
//            }
//            case CHHapticEngineStoppedReasonSystemError: {
//                NSLog(@"REASON: System Error");
//                // The system faulted, so either continue without haptics or terminate the app.
//                break;
//            }
//        }
//    }];
//
//    [_engine startWithCompletionHandler:^(NSError* returnedError) {
//        if (returnedError)
//            NSLog(@"--- Error starting haptic engine: %@", returnedError.debugDescription);
//    }];
//        
//    [_player startAtTime:CHHapticTimeImmediate error:&error];
//    
//    [_engine stopWithCompletionHandler:^(NSError* _Nullable error) {
//        if (error)
//            NSLog(@"--- Error stopping haptic engine: %@", error.debugDescription);
//    }];
    

    haptic_feedback = [[UISelectionFeedbackGenerator alloc] init];
    [haptic_feedback prepare];
    
    touch_handler = touch_handler_init(self);
    [self setNeedsDisplay];
    
    map(buttons)(^ UIButton * (unsigned int index) {
        UIButton * button;
        [button = [UIButton new] setTag:index];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[0][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateDeselected)] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateSelected)] forState:UIControlStateSelected];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateHighlighted)] forState:UIControlStateHighlighted];
        [button sizeToFit];
        [button setUserInteractionEnabled:FALSE];
        
        float angle = 270.0 - ((90.0 / 4.0) * index);
//        angle = degreesToRadians(angle);
        NSNumber * button_angle = [NSNumber numberWithFloat:angle];
        objc_setAssociatedObject (
            button,
            (void *)button.tag,
            button_angle,
            OBJC_ASSOCIATION_RETAIN
        );
        
        void (^eventHandlerBlockTouchUpInside)(void) = ^{
            NSNumber *associatedObject =
                        (NSNumber *) objc_getAssociatedObject (button, (void *)button.tag);
                    NSLog(@"associatedObject: %f", associatedObject.floatValue);
        };
        objc_setAssociatedObject(button, @selector(invoke), eventHandlerBlockTouchUpInside, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [button addTarget:eventHandlerBlockTouchUpInside action:@selector(invoke) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        [button setCenter:[[UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds)) radius:CGRectGetMidX(self.bounds) startAngle:button_angle.floatValue endAngle:button_angle.floatValue clockwise:FALSE] currentPoint]];
        return button;
    });
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ (handle_touch = touch_handler(touches.anyObject))(nil); });
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ handle_touch(nil); });
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ handle_touch(set_state); });
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ handle_touch(set_state); });
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));

    for (NSUInteger t = (NSUInteger)180; t <= (NSUInteger)270; t++) {
        CGFloat angle = degreesToRadians(t);
//        NSUInteger property_value_angle = rescale(self->propertyValue, 0.0, 100.0, 180.0, 270.0);
//        printf("property_value_angle = %f\n", property_value_angle);
        CGFloat tick_height = (t == (NSUInteger)180 || t == (NSUInteger)270) ? 10.0 : (t % 10 == 0) ? 6.0 : 3.0;
        {
            CGPoint xy_outer = CGPointMake(((self.radius + tick_height) * cosf(angle)),
                                           ((self.radius + tick_height) * sinf(angle)));
            CGPoint xy_inner = CGPointMake(((self.radius - tick_height) * cosf(angle)),
                                           ((self.radius - tick_height) * sinf(angle)));
            CGContextSetStrokeColorWithColor(ctx, (t <= self->propertyValue) ? [[UIColor systemGreenColor] CGColor] : [[UIColor systemRedColor] CGColor]);
            CGContextSetLineWidth(ctx, (t == 180 || t == 270) ? 2.0 : (t % 10 == 0) ? 1.0 : 0.625);
            CGContextMoveToPoint(ctx, xy_outer.x + CGRectGetMaxX(rect), xy_outer.y + CGRectGetMaxY(rect));
            CGContextAddLineToPoint(ctx, xy_inner.x + CGRectGetMaxX(rect), xy_inner.y + CGRectGetMaxY(rect));
        }

        CGContextStrokePath(ctx);
    }
}

@end
