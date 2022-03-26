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
//#include <stdatomic.h>
//#include <libkern/OSAtomic.h>
//#include <stdatomic.h>
#import "VideoCamera.h"

@import simd;


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
    UIImageSymbolConfiguration * symbol_point_size_weight = [UIImageSymbolConfiguration configurationWithPointSize:42.0 weight:UIImageSymbolWeightLight];
    switch (state) {
        case CaptureDeviceConfigurationControlStateDeselected: {
            UIImageSymbolConfiguration * symbol_color             = [UIImageSymbolConfiguration configurationWithHierarchicalColor:[UIColor systemBlueColor]];
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

static CGPoint center_point;
static UISnapBehavior * snap[5];
static UICollisionBehavior * collision;
static UIDynamicAnimator * animator;
static UIGravityBehavior * gravity;
static __strong const UIButton * _Nonnull buttons[5];
static const UIButton * (^capture_device_configuration_control_property_button)(CaptureDeviceConfigurationControlProperty) = ^ (CaptureDeviceConfigurationControlProperty property) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [buttons[property] setSelected:(selected_property_bit_vector >> property) & 1UL];
        [buttons[property] setHidden:(hidden_property_bit_vector >> property) & 1UL];
        [buttons[property] setHighlighted:(highlighted_property_bit_vector >> property) & 1UL];
    });
    
    return buttons[property];
};

static void (^(^map)(__strong const UIButton * _Nonnull [_Nonnull 5]))(const UIButton * (^__strong)(unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    return ^ (const UIButton *(^enumeration)(unsigned int)) {
        dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t index) {
            dispatch_barrier_async(dispatch_get_main_queue(), ^{
                buttons[index] = enumeration((unsigned int)index);
            });
        });
    };
};

int setBit(int x, unsigned char position) {
    int mask = 1 << position;
    return x | mask;
}

int clearBit(int x, unsigned char position) {
    int mask = 1 << position;
    return x & ~mask;
}

int modifyBit(int x, unsigned char position, bool newState) {
    int mask = 1 << position;
    int state = (int)(newState); // relies on true = 1 and false = 0
    return (x & ~mask) | (-state & mask);
}

int flipBit(int x, unsigned char position) {
    int mask = 1 << position;
    return x ^ mask;
}

bool isBitSet(long x, unsigned char position) {
    x >>= position;
    return (x & 1) != 0;
}

int extractBit(int bit_vector, int length, int position)
{
    return (((1 << length) - 1) & (bit_vector >> (position - 1)));
}

//static long (^(^iterator)(long))(long(^)(long)) = ^ (long bit_vector_mask) {
//    bit_vector_mask >>= 1;
//    printf("bit_vector_mask == %ld\n", bit_vector_mask);
//    return ^ long (long(^set_bit)(long)) {
//        printf("set_bit == %ld\n", bit_vector_mask);
//        return ((bit_vector_mask & 1UL)
//                & ^ long (long bit_counter) {
//            printf("bit_counter == %ld\n", bit_counter);
//
//            bit_counter >>= 1;
//            return set_bit(bit_counter);
//        }(bit_vector_mask))
//        || ^ long (long bit_counter) {
//            printf("bit_counter == %ld\n", bit_counter);
//
//            bit_counter >>= 1;
//            return set_bit(bit_counter);
//        }(bit_vector_mask);
//    };
//};
//
//static NSString * (^NSStringFromBitVector)(long) = ^ NSString * (long bit_vector) {
//    __block NSMutableString * bit_vector_str = [[NSMutableString alloc] init];
//    iterator(bit_vector)(^ long (long bit) {
//        [bit_vector_str appendString:[NSString stringWithFormat:@"%ld", bit]];
//        return bit;
//    });
////    ((bit_vector >>= 1UL) & 1UL);
////    printf("bit_vector_str == %s\n", [bit_vector_str UTF8String]);
//    return (NSString *)bit_vector_str;
//};

static typeof(CADisplayLink *) display_link;
static long (^(^integrate)(long))(long(^__strong)(long)) = ^ (long duration) {
    [display_link invalidate];
    __block /* _Atomic */ long frames = ~(1 << (duration + 1));
    __block long frame;
    //    __block long(^cancel)(CADisplayLink *);
    //    return ^ long (long(^__strong integrand)(long)) {
    return ^ long (long(^__strong integrand)(long)) {
        display_link = [CADisplayLink displayLinkWithTarget:^{
            dispatch_barrier_async_and_wait(enumerator_queue(), ^{
                frames >>= 1;
                ((frames & 1) && ^ long {
                    frame = floor(log2(frames));
                    //                    static long (^(^integrate)(long))(long(^ _Nullable (^__strong)(long))(CADisplayLink *)) = ^ (long duration) {
                    //                        return ^ long (long(^ _Nullable (^__strong integrand)(long))(CADisplayLink *)) {
                    //                    ((long)0 || (cancel = (integrand(frame)))) && cancel(display_link); // runs a cancel handler if one was provided
                    
//                    dispatch_barrier_async_and_wait(enumerator_queue(), ^{ integrand(frame); });
                    integrand(frame);
                    return active_component_bit_vector;
                }())
                
                ||
                
                ((frames | 1) && ^ long {
                    [display_link invalidate];
                    return active_component_bit_vector;
                }());
            });
        } selector:@selector(invoke)];
        [display_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        return active_component_bit_vector;
    };
};

static const long (^(^(^state_setter)(long(^ _Nullable)(void)))(long(^ _Nullable)(void)))(long(^ _Nullable)(void)) = ^ (long (^ _Nonnull __strong pre_set_state_animation)(void)) {
    pre_set_state_animation();
    // selected (converse nonimplication)
    selected_property_bit_vector = highlighted_property_bit_vector & active_component_bit_vector;
    
    // hidden (exclusive disjunction)
    hidden_property_bit_vector = (~selected_property_bit_vector & active_component_bit_vector);
    
    // highlighted
    highlighted_property_bit_vector = active_component_bit_vector ^ active_component_bit_vector;
    
    // active_component
    active_component_bit_vector = ~active_component_bit_vector;
    return ^ (long (^ _Nonnull __strong transition)(void)) {
        
        transition();
        return ^ (long (^ _Nonnull __strong post_set_state_animation)(void)) {
            return post_set_state_animation();
        };
    };
};

static const void (^draw_tick_wheel)(CGContextRef, CGRect);
static const void (^ const (* restrict draw_tick_wheel_ptr))(CGContextRef, CGRect) = &draw_tick_wheel;

static const long (^(^(^state_setter)(long(^ _Nullable)(void)))(long(^ _Nullable)(void)))(long(^ _Nullable)(void));
static const long (^(^(^__strong * restrict state_setter_ptr)(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)) = &state_setter;

static const long (^(^_Nonnull touch_handler)(__strong UITouch * _Nullable))(const long (^(^(^__strong * restrict state_setter_ptr)(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)));
static const long (^ _Nonnull  handle_touch)(const long (^(^(^__strong * restrict state_setter_ptr)(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)));
static long (^(^(^touch_handler_init)(const ControlView * __strong))(__strong UITouch * _Nullable))(const long (^(^(^__strong * restrict state_setter_ptr)(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void))) = ^ (const ControlView * __strong view) {
    center_point = CGPointMake(CGRectGetMaxX(((ControlView *)view).bounds), CGRectGetMaxY(((ControlView *)view).bounds));
    
    static float radius;
    radius = CGRectGetMidX(((ControlView *)view).bounds) * 1.5;
    static void (^(^(^(^(^radius_from_point_init)(float *))(CGPoint *))(float, float))(void(^)(float *, CGPoint *, float, float, CGPoint)))(CGPoint) = ^ (float * restrict result_ptr_t) {
        return ^ (CGPoint * origin_point) {
            return ^ (float bounds_min, float bounds_max) {
                return ^ (void(^calculation)(float *, CGPoint *, float, float, CGPoint)) {
                    return ^ (CGPoint intersection_point) {
                        calculation(result_ptr_t, origin_point, bounds_min, bounds_max, intersection_point);
                    };
                };
            };
        };
    };
    
    static float angle;
    static float angle_offset;
    static unsigned long (^(^(^(^(^angle_from_point_init)(float *))(CGPoint *))(float, float))(unsigned long(^)(float *, CGPoint *, float, float, CGPoint)))(CGPoint) = ^ (float * restrict result_ptr_t) {
        return ^ (CGPoint * origin_point) {
            return ^ (float bounds_min, float bounds_max) {
                return ^ (unsigned long(^calculation)(float *, CGPoint *, float, float, CGPoint)) {
                    return ^ (CGPoint intersection_point) {
                        return calculation(result_ptr_t, origin_point, bounds_min, bounds_max, intersection_point);
                    };
                };
            };
        };
    };
    
    static unsigned long (^angle_from_point)(CGPoint);
    angle_from_point = angle_from_point_init(&angle)(&center_point)(180.0, 270.0)
    (^ (float * result, CGPoint * origin, float min, float max, CGPoint intersection) {
        *result = (atan2(intersection.y - (*origin).y, intersection.x - (*origin).x)) * (min / M_PI);
        *result = (!(*result < 0.0) ?: (*result += 360.0));
        *result = fmaxf(min, fminf(*result, max));
        
        return (active_component_bit_vector & BUTTON_ARC_COMPONENT_BIT_MASK);
    });
    
    static void (^radius_from_point)(CGPoint);
    radius_from_point = radius_from_point_init(&radius)(&center_point)(CGRectGetMidX(((ControlView *)view).bounds), center_point.x)
    (^ (float * result, CGPoint * origin, float min, float max, CGPoint intersection) {
        *result = sqrt(pow(intersection.x - (*origin).x, 2.0) + pow(intersection.y - (*origin).y, 2.0));
        *result = fmaxf(min, fminf(*result, max));
    });
    
    CGPoint (^point_from_angle)(float) = ^ (CGPoint * origin_point) {
        return ^ (float bounds_min, float bounds_max) {
            return ^ (CGPoint(^calculation)(CGPoint *, float, float, float *, float)) {
                return ^ CGPoint (float degrees){
                    degrees = (degrees * kRadians_f);
                    return calculation(origin_point, bounds_min, bounds_max, &radius, degrees);
                };
            };
        };
    }(&center_point)(180.f, 270.f)(^ (CGPoint * origin, float min, float max, float * r, float radians) {
        return CGPointMake((*origin).x - *r * -cos(radians), (*origin).y - *r * -sin(radians));
    });
    
    static long (^animate)(long(^)(UIDynamicAnimator *, UISnapBehavior *, size_t));
    static long (^(^animate_init)(ControlView *))(long(^)(UIDynamicAnimator *, UISnapBehavior *, size_t));
    ((animate = (animate_init = ^ (ControlView * control_view) {
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:control_view];
        return ^ long (long(^animation)(UIDynamicAnimator *, UISnapBehavior *, size_t)) {
            dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    animation(animator, snap[index], index);
                });
            });
            [animator removeAllBehaviors];
            return TRUE_BIT;
        };
    })(view)))(^ long (UIDynamicAnimator * dynamic_animator, UISnapBehavior * snap_behavior, size_t index) {
        [snap_behavior = [[UISnapBehavior alloc] initWithItem:buttons[index] snapToPoint:point_from_angle(rescale(index, 0.0, 4.0, 180.0, 270.0))] setDamping:1.0];
        [dynamic_animator addBehavior:snap_behavior];
        return TRUE_BIT;
    });
    
    draw_tick_wheel = ^ (ControlView * view, float * restrict angle_t, float * restrict radius_t) {
        return ^ (CGContextRef ctx, CGRect rect) {
            dispatch_barrier_sync(enumerator_queue(), ^{
                ((active_component_bit_vector ^ BUTTON_ARC_COMPONENT_BIT_MASK) && ^ unsigned long (void) {
                    UIGraphicsBeginImageContextWithOptions(rect.size, FALSE, 1.0);
                    CGContextTranslateCTM(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
                    for (unsigned int t = 180; t <= 270; t++) {
                        float angle = t * kRadians_f;
                        float tick_height = (t == 180 || t == 270) ? 9.0 : (t % (unsigned int)round((270 - 180) / 9.0) == 0) ? 6.0 : 3.0;
                        {
                            CGPoint xy_outer = CGPointMake(((*radius_t + tick_height) * cosf(angle)),
                                                           ((*radius_t + tick_height) * sinf(angle)));
                            CGPoint xy_inner = CGPointMake(((*radius_t - tick_height) * cosf(angle)),
                                                           ((*radius_t - tick_height) * sinf(angle)));
                            CGContextSetStrokeColorWithColor(ctx, (t <= *angle_t) ? [[UIColor systemGreenColor] CGColor] : [[UIColor systemRedColor] CGColor]);
                            CGContextSetLineWidth(ctx, (t == 180 || t == 270) ? 2.0 : (t % 9 == 0) ? 1.0 : 0.625);
                            CGContextMoveToPoint(ctx, xy_outer.x + CGRectGetMaxX(rect), xy_outer.y + CGRectGetMaxY(rect));
                            CGContextAddLineToPoint(ctx, xy_inner.x + CGRectGetMaxX(rect), xy_inner.y + CGRectGetMaxY(rect));
                        };
                        CGContextStrokePath(ctx);
                    }
                    UIGraphicsEndImageContext();
                    return TRUE_BIT;
                }()) || ((active_component_bit_vector & BUTTON_ARC_COMPONENT_BIT_MASK) && ^ unsigned long (void) {
                    CGContextClearRect(ctx, rect);
                    return TRUE_BIT;
                }());
            });
        };
    }((ControlView *)view, &angle, &radius);
    
    __block UISelectionFeedbackGenerator * haptic_feedback;
    haptic_feedback = [[UISelectionFeedbackGenerator alloc] init];
    [haptic_feedback prepare];
    
    unsigned long (^(^test)(UITouchPhase))(const UIButton __strong * _Nonnull)  = ^ (UITouchPhase touch_phase) {
//        __block UIDynamicAnimator * dynamic_animator = [[UIDynamicAnimator alloc] initWithReferenceView:view];
//        __block UISnapBehavior * snap_behavior;
//        [snap_behavior setDamping:1.0];
        return ^  (unsigned long(^invoke)(const UIButton __strong * _Nonnull)) {
            return (^{
//                [dynamic_animator removeAllBehaviors];
                !!(((~selected_property_bit_vector & active_component_bit_vector) ^ selected_property_bit_vector) >> 0) && invoke(buttons[0]);
                !!(((~selected_property_bit_vector & active_component_bit_vector) ^ selected_property_bit_vector) >> 1) && invoke(buttons[1]);
                !!(((~selected_property_bit_vector & active_component_bit_vector) ^ selected_property_bit_vector) >> 2) && invoke(buttons[2]);
                !!(((~selected_property_bit_vector & active_component_bit_vector) ^ selected_property_bit_vector) >> 3) && invoke(buttons[3]);
                !!(((~selected_property_bit_vector & active_component_bit_vector) ^ selected_property_bit_vector) >> 4) && invoke(buttons[4]);
                return ^{
                    return invoke;
                };
            }()());
        }(^ unsigned long (const UIButton __strong * _Nonnull button) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [button setHighlighted:(highlighted_property_bit_vector >> button.tag) & 1UL];
                [button setSelected:(selected_property_bit_vector >> button.tag) & 1UL];
                [button setHidden:(hidden_property_bit_vector >> button.tag) & 1UL];
                ((active_component_bit_vector & BUTTON_ARC_COMPONENT_BIT_MASK) && angle_from_point(point_from_angle(rescale(button.tag, 0.0, 4.0, 180.0, 270.0))));
//                (touch_phase & UITouchPhaseBegan && ^{
//                    snap_behavior = [[UISnapBehavior alloc] initWithItem:button snapToPoint:button_center];
//                    [dynamic_animator addBehavior:snap_behavior];
//                    return TRUE_BIT;
//                });
                [button setCenter:point_from_angle(angle + angle_offset)];
            });
            return button.tag;
        });
    };
    
    __block unsigned long touch_property;
    
    return ^ (__strong UITouch * _Nullable touch) { // handle_touch:
        return ^ (const long (^(^(^__strong * restrict state_setter_t)(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void)))(long (^ _Nullable __strong)(void))) {
            ^ (CGPoint touch_point) {
                touch_point.x = fmaxf(CGRectGetMinX(view.bounds),                               fminf(touch_point.x, center_point.x));
                touch_point.y = fmaxf(CGRectGetMaxY(view.bounds) - CGRectGetWidth(view.bounds), fminf(touch_point.y, center_point.y));
                radius_from_point(touch_point);
                angle_from_point(touch_point);
            }([touch locationInView:(ControlView *)view]);
            
            typeof(touch_property) new_touch_property;
            (active_component_bit_vector & BUTTON_ARC_COMPONENT_BIT_MASK) && ((new_touch_property = (unsigned int)round(rescale(angle, 180.0, 270.0, 0.0, 4.0))) ^ touch_property) && (highlighted_property_bit_vector = (1UL << (^ unsigned long {
                [haptic_feedback selectionChanged];
                [haptic_feedback prepare];
                return (unsigned long)(touch_property = new_touch_property);
            }())));
            
            test(touch.phase);
            ((active_component_bit_vector & ~BUTTON_ARC_COMPONENT_BIT_MASK) && (^ unsigned long {
                [(ControlView *)view setNeedsDisplay];
                return TRUE_BIT;
            })());
            
            ((long)0 || state_setter_t) && ((*state_setter_t)(^ long {
                integrate(30)(^ long (long frame) {
                    angle_offset = ((360.0 / 30) * frame);
                    test(UITouchPhaseCancelled);
                    return frame;
                });
                //                ^ (ControlView * control_view) {
                //                    animator = [[UIDynamicAnimator alloc] initWithReferenceView:control_view];
                //                    angle_from_point(center_point);
                //                    radius_from_point(center_point);
                //                    return ^ long (long(^animation)(UIDynamicAnimator *, UISnapBehavior *, size_t)) {
                //                        dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t index) {
                //                            dispatch_barrier_async(dispatch_get_main_queue(), ^{
                //                                animation(animator, snap[index], index);
//                            });
//                        });
//                        [animator removeAllBehaviors];
//                        return TRUE_BIT;
//                    };
//                }(view)(^ long (UIDynamicAnimator * dynamic_animator, UISnapBehavior * snap_behavior, size_t index) {
//                    // To-Do: Update radius and angle per new center point
//                    [snap_behavior = [[UISnapBehavior alloc] initWithItem:buttons[index] snapToPoint:center_point] setDamping:1.0];
//                    [dynamic_animator addBehavior:snap_behavior];
//                    return TRUE_BIT;
//                });
                return TRUE_BIT;
            })(^ long {
                ((active_component_bit_vector & ~BUTTON_ARC_COMPONENT_BIT_MASK) && (^ long {
                    unsigned int selected_property_bit_position = floor(log2(selected_property_bit_vector));
                    switch (selected_property_bit_position) {
                        case CaptureDeviceConfigurationControlPropertyTorchLevel:
                            angle = (rescale(VideoCamera.captureDevice.torchLevel, 0.0, 1.0, 180.0, 270.0));
                            break;
                        case CaptureDeviceConfigurationControlPropertyLensPosition:
                            angle = (rescale(VideoCamera.captureDevice.lensPosition, 0.0, 1.0, 180.0, 270.0));
                            break;
                        case CaptureDeviceConfigurationControlPropertyExposureDuration: {
                            double newDurationSeconds = CMTimeGetSeconds( VideoCamera.captureDevice.exposureDuration );
                            double minDurationSeconds = MAX(CMTimeGetSeconds( VideoCamera.captureDevice.activeFormat.minExposureDuration ), kExposureMinimumDuration);
                            double maxDurationSeconds = 1.0/3.0;
                            double normalized_duration = fmaxf(0.0, fminf(pow(rescale(newDurationSeconds, minDurationSeconds, maxDurationSeconds, 0.0, 1.0), 1.0 / kExposureDurationPower), 1.0));
                            angle = rescale(normalized_duration, 0.0, 1.0, 180.0, 270.0);
                            break;
                        }
                        case CaptureDeviceConfigurationControlPropertyISO:
                            angle = (rescale(VideoCamera.captureDevice.ISO, VideoCamera.captureDevice.activeFormat.minISO, VideoCamera.captureDevice.activeFormat.maxISO, 180.0, 270.0));
                            break;
                        case CaptureDeviceConfigurationControlPropertyVideoZoomFactor:
                            angle = (rescale(VideoCamera.captureDevice.videoZoomFactor, 1.0, 9.0, 180.0, 270.0));
                            break;
                        default:
                            return ~BUTTON_ARC_COMPONENT_BIT_MASK;
                            break;
                    }
                    return (long)TRUE_BIT;
                })());
                return (long)TRUE_BIT;
            })(^ long {
//                ^ (ControlView * control_view) {
//                    animator = [[UIDynamicAnimator alloc] initWithReferenceView:control_view];
//                    return ^ long (long(^animation)(UIDynamicAnimator *, UISnapBehavior *, size_t)) {
//                        dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t index) {
//                            dispatch_barrier_async(dispatch_get_main_queue(), ^{
//                                animation(animator, snap[index], index);
//                            });
//                        });
//                        [animator removeAllBehaviors];
//                        return TRUE_BIT;
//                    };
//                }(view)(^ long (UIDynamicAnimator * dynamic_animator, UISnapBehavior * snap_behavior, size_t index) {
//                    // To-Do: Update radius and angle per new center point
//                    ((active_component_bit_vector & BUTTON_ARC_COMPONENT_BIT_MASK) && angle_from_point(point_from_angle(rescale(index, 0.0, 4.0, 180.0, 270.0))));
//                    CGPoint new_center_point = point_from_angle(angle);
//                    [snap_behavior = [[UISnapBehavior alloc] initWithItem:buttons[index] snapToPoint:new_center_point] setDamping:1.0];
//                    [dynamic_animator addBehavior:snap_behavior];
//                    return TRUE_BIT;
//                });
                return (long)TRUE_BIT;
            }));
            [(ControlView *)view setNeedsDisplay];
            return (long)test(touch.phase);
        };
    };
};

// To-Do: Get bit field length using sizeof() and then subtract value returned by ctz (e.g., count trailing zeros)
unsigned long (^(^bits)(unsigned long))(unsigned long)  = ^ (unsigned long x) {
    return ^ (unsigned long(^bit_operation)(unsigned long)) {
        return (^{
            printf("\n%lu%lu%lu%lu%lu\n",
                   bit_operation((x >> 0) & 1UL),
                   bit_operation((x >> 1) & 1UL),
                   bit_operation((x >> 2) & 1UL),
                   bit_operation((x >> 3) & 1UL),
                   bit_operation((x >> 4) & 1UL));
            return ^{
                return bit_operation;
            };
        }()());
    }(^ unsigned long (unsigned long bit) {
        return bit;
    });
};

@implementation ControlView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    //    bits(BUTTON_ARC_COMPONENT_BIT_MASK);
    //    bits(TICK_WHEEL_COMPONENT_BIT_MASK);
    bits(active_component_bit_vector ^ TICK_WHEEL_COMPONENT_BIT_MASK);
    //    bits(~selected_property_bit_vector);
    
    CGPoint default_center_point = CGPointMake(CGRectGetMaxX(((ControlView *)self).bounds), CGRectGetMaxY(((ControlView *)self).bounds));
    float default_radius         = CGRectGetMaxX(((ControlView *)self).bounds);
    
    map(buttons)(^ const UIButton * (unsigned int index) {
        const UIButton * button;
        [button = [UIButton new] setTag:index];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[0][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateDeselected)] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateSelected)] forState:UIControlStateSelected];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateHighlighted)] forState:UIControlStateHighlighted];
        
        [button sizeToFit];
        
        float angle = rescale(index, 0.0, 4.0, 180.0, 270.0);
        NSNumber * button_angle = [NSNumber numberWithFloat:angle];
        objc_setAssociatedObject (button,
                                  (void *)index,
                                  button_angle,
                                  OBJC_ASSOCIATION_RETAIN);
        
        [button setUserInteractionEnabled:FALSE];
        void (^eventHandlerBlockTouchUpInside)(void) = ^{
            NSNumber * associatedObject = (NSNumber *)objc_getAssociatedObject (button, (void *)index);
            //            printf("%s\n", [[associatedObject stringValue] UTF8String]);
        };
        objc_setAssociatedObject(button, @selector(invoke), eventHandlerBlockTouchUpInside, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [button addTarget:eventHandlerBlockTouchUpInside action:@selector(invoke) forControlEvents:UIControlEventTouchUpInside];
        
        angle = angle * kRadians_f;
        [button setCenter:default_center_point];
        CGPoint target_center = [[UIBezierPath bezierPathWithArcCenter:default_center_point radius:default_radius startAngle:angle endAngle:angle clockwise:FALSE] currentPoint];
        
        [self addSubview:button];
        
        return button;
    });
    
    touch_handler = touch_handler_init((ControlView *)self);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (handle_touch = touch_handler(touches.anyObject))(nil);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    handle_touch(nil);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    handle_touch(state_setter_ptr);
};

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    handle_touch(nil);
}

- (void)drawRect:(CGRect)rect {
    (*draw_tick_wheel_ptr)(UIGraphicsGetCurrentContext(), rect);
}

//- (void)updateStateLabels {
//        [self.stateBitVectorLabel setText:NSStringFromBitVector(active_component_bit_vector)];
//        [self.highlightedBitVectorLabel setText:NSStringFromBitVector(highlighted_property_bit_vector)];
//        [self.selectedBitVectorLabel setText:NSStringFromBitVector(selected_property_bit_vector)];
//        [self.hiddenBitVectorLabel setText:NSStringFromBitVector(hidden_property_bit_vector)];
//}

@end
