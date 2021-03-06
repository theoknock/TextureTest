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
#include <stdatomic.h>
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

const unsigned int capture_device_configuration_control_property_torch_level_bit = (1UL << 0);
const unsigned int capture_device_configuration_control_property_lens_position_bit = (1UL << 1);
const unsigned int capture_device_configuration_control_property_exposure_duration_bit = (1UL << 2);
const unsigned int capture_device_configuration_control_property_iso_bit = (1UL << 3);
const unsigned int capture_device_configuration_control_property_video_zoom_factor_bit = (1UL << 4);
#define MASK_ALL  (capture_device_configuration_control_property_torch_level_bit | capture_device_configuration_control_property_lens_position_bit | capture_device_configuration_control_property_exposure_duration_bit | capture_device_configuration_control_property_iso_bit | capture_device_configuration_control_property_video_zoom_factor_bit)
#define MASK_NONE (  0 << 0 |   0 << 1 |   0 << 2 |   0 << 3 |   0 << 4)
_Atomic unsigned int active_component_bit_vector     = MASK_ALL;
_Atomic unsigned int highlighted_property_bit_vector = MASK_NONE;
_Atomic unsigned int selected_property_bit_vector    = MASK_NONE;
_Atomic unsigned int hidden_property_bit_vector      = MASK_NONE;

static __strong UIButton * _Nonnull buttons[5];
static UIButton * (^capture_device_configuration_control_property_button)(CaptureDeviceConfigurationControlProperty) = ^ (CaptureDeviceConfigurationControlProperty property) {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        [buttons[property] setSelected:(selected_property_bit_vector >> property) & 1UL];
        [buttons[property] setHidden:(hidden_property_bit_vector >> property) & 1UL];
        [buttons[property] setHighlighted:(highlighted_property_bit_vector >> property) & 1UL];
    });
    
    return (UIButton *)buttons[property];
};

static dispatch_queue_t enumerator_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("enumerator_queue()", NULL);
    });
    
    return queue;
};

static void (^(^map)(__strong UIButton * _Nonnull [_Nonnull 5]))(UIButton * (^__strong)(unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    return ^ (UIButton *(^enumeration)(unsigned int)) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            dispatch_apply(5, enumerator_queue(), ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    button_collection[index] = enumeration((unsigned int)index);
                });
            });
        });
    };
};

static uint8_t (^(^filter)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    return ^ uint8_t (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
        dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t index) {
            enumeration(capture_device_configuration_control_property_button(index), (unsigned int)index);
        });
        return active_component_bit_vector;
    };
};





//static long (^(^integrate)(long))(long(^ _Nullable (^__strong)(long))(void)) = ^ (long duration) {
//    __block long frames = ~(1 << (duration + 1));
//    __block long(^cancel)(void);
//    __block long frame;
//    return ^ long (long(^ _Nullable (^__strong integrand)(long))(void)) {
//        dispatch_barrier_async(enumerator_queue(), ^{
//            dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_APPLY_AUTO);
//            dispatch_source_set_timer(timer, DISPATCH_TIMER_STRICT, (1.0/duration) * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
//            dispatch_source_set_event_handler(timer, ^{
//                frames >>= 1;
//                ((frames & 1) && ^ long {
//                    frame = (long)Log2n((unsigned int)frames);
//                    ((long)0 || (cancel = (integrand(frame)))) && cancel(); // runs a cancel handler if one was provided
//                    printf("\tframe == %ld\n", frame);
//                    return active_component_bit_vector;
//                }())
//
//                ||
//
//                ((frames | 1) &&  ^ long {
//                    dispatch_suspend(timer);
//                    printf("animation end\n");
//                    return active_component_bit_vector;
//                }());
//            });
//            printf("animation begin\t\t\t---------------\t\t\t");
//            dispatch_resume(timer);
//        });
//
//        return active_component_bit_vector;
//    };
//};



//void (^test)(void) = ^{
//    __block int i = 0;
//    void(^block(void(^)(void)))(void(^(^)(void))(void));
//    block(^{
//        printf("%d\n", i++);
//    })(^{
//        printf("%d\n", i++);
//        return ^{
//            printf("%d\n", i++);
//        };
//    });
//};

//
//void (^test2)(void) = ^{
//    void(^(^__strong blk2)(void))(long) = ^ {
//        // state change
//        return ^ (long end) {
//            // ending animation
//        };
//    };
//    void(^(^__strong blk1)(long))(void) = ^ (long start) {
//        // starting animation
//        return ^{
//            // state change
//        };
//    };
//    void (^(^(^blk3)(long))(void))(long) = ^ (long start) {
//        // starting animation
//        return ^ {
//            // state change
//            return ^ (long end) {
//                // ending animation
//            };
//        };
//    };
//
//    blk3((long)1/* start_animation */)(/* set_state */)((long)1/* end_animation */);
//    // this does not ensure a single transaction, as each block could be called individually - the output of one must be the input of another and the invoker of it, as well:
//    //          animate(starting_animation(state_change));
////    long(^transition)(long(^(^animations)(long(^state)(void)))(void));
//    long(^transition)(long(^animate)(void(^(^state)(void))(long)));
//
//
//
//    blk1((long)1)();
//    blk2()((long)1);
//};

static NSString * (^NSStringFromBitVector)(uint8_t, unsigned int) = ^ NSString * (uint8_t bit_vector, unsigned int length) {
    NSMutableString * bit_vector_str = [[NSMutableString alloc] initWithCapacity:length];
    for (int property = 0; property < length; property++)
        [bit_vector_str appendString:[NSString stringWithFormat:@"%d", (bit_vector & (1 << property)) >> property]];
    return (NSString *)bit_vector_str;
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

bool isBitSet(int x, unsigned char position) {
    x >>= position;
    return (x & 1) != 0;
}

int extractBit(int bit_vector, int length, int position)
{
    return (((1 << length) - 1) & (bit_vector >> (position - 1)));
}

typedef long (^Log2n_Block)(unsigned int);
static Log2n_Block Log2n_recursive = ^ long (unsigned int property) {
    return (property > 1) ? 1 + Log2n_recursive(property / 2) : 0;
};

//static Log2n_Block Log2n = ^ (unsigned int bit_vector) {
//    return Log2n_recursive(extractBit(bit_vector, 5, 1));
//};

static long (^(^reduce)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    return ^ long (void(^reduction)(UIButton * _Nonnull, unsigned int)) {
        dispatch_apply(1, DISPATCH_APPLY_AUTO, ^(size_t index) {
            unsigned int selected_property_bit_position = Log2n_recursive(selected_property_bit_vector);
            reduction(capture_device_configuration_control_property_button(selected_property_bit_position), selected_property_bit_position);

        });
        return active_component_bit_vector;
    };
};

static long (^(^integrate)(long))(long(^ _Nullable (^__strong)(long))(CADisplayLink *)) = ^ (long duration) {
    __block typeof(CADisplayLink *) display_link;
    __block long frames = ~(1 << (duration + 1));
    __block long frame;
    __block long(^cancel)(CADisplayLink *);
    return ^ long (long(^ _Nullable (^__strong integrand)(long))(CADisplayLink *)) {
        display_link = [CADisplayLink displayLinkWithTarget:^{
            frames >>= 1;
            return
            ((frames & 1) && ^ long {
                frame = (long)Log2n_recursive((unsigned int)frames);
                ((long)0 || (cancel = (integrand(frame)))) && cancel(display_link); // runs a cancel handler if one was provided
                return active_component_bit_vector;
            }())
            
            ||
            
            ((frames | 1) && ^ long {
                [display_link invalidate];
                return active_component_bit_vector;
            }());
        } selector:@selector(invoke)];
        [display_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        return active_component_bit_vector;
    };
};

// _Nullable block parameters must return long (for bitwise-null predicate)
// _Nonnull block parameters can return void
long (^set_state)(void (^ _Nonnull)(long (^ _Nullable)(void))) = ^ long (void (^ _Nonnull touch_handler)(long (^ _Nullable)(void))) {
    dispatch_barrier_async(enumerator_queue(), ^{
        active_component_bit_vector = ~active_component_bit_vector;
        
        // converse nonimplication
        uint8_t selected_property_bit_mask = MASK_NONE;
        uint8_t selected_property_bit_position = (Log2n_recursive(selected_property_bit_vector));
        uint8_t highlighted_property_bit_position = (Log2n_recursive(highlighted_property_bit_vector));
        selected_property_bit_mask ^= (1UL << highlighted_property_bit_position) & ~active_component_bit_vector;
        selected_property_bit_vector = (selected_property_bit_vector | selected_property_bit_mask) & ~selected_property_bit_vector;
        
        // exclusive disjunction
        hidden_property_bit_vector = ~active_component_bit_vector;
        hidden_property_bit_vector = selected_property_bit_mask & ~active_component_bit_vector;
        hidden_property_bit_vector ^= MASK_ALL;
        hidden_property_bit_vector ^= active_component_bit_vector;
        
        // highlighted_reset
        //    highlighted_property_bit_vector = ~active_component_bit_vector;
        //    highlighted_property_bit_vector = MASK_NONE & ~active_component_bit_vector;
        //    highlighted_property_bit_vector ^= MASK_ALL;
        //    highlighted_property_bit_vector ^= active_component_bit_vector;
        
        
        
        
        
        // To-Do: Split the animations in half, with 5 buttons exiting and one entering and vice versa
        //        (maybe by setting state between exit and entrance)
        //    return ^ long (CGPoint center_point, CGFloat radius) {
        //        ((active_component_bit_vector & MASK_ALL) &&
        //         integrate((long)30)(^ (long frame) {
        //            return ^ long (CADisplayLink * display_link) {
        //                CGFloat angle_adj = (360.0 / 30.0) * frame;
        //                filter(buttons)(^{
        //                    return ^ (UIButton * _Nonnull button, unsigned int index) {
        //                        dispatch_barrier_async(dispatch_get_main_queue(), ^{
        //                            [button setCenter:^ (CGFloat radians) {
        //                                return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
        //                            }(degreesToRadians(rescale(index, 0.0, 4.0, 180.0 + angle_adj, 270.0 + angle_adj)))];
        //                        });
        //                    };
        //                }());
        //                return (long)1;
        //            };
        //        }))
        //
        //        ||
        //
        //        ((active_component_bit_vector & ~MASK_ALL) &&
        //         integrate((long)30)(^ (long frame) {
        //            return ^ long (CADisplayLink * display_link) {
        //                CGFloat angle_adj = (360.0 / 30.0) * frame;
        //                reduce(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
        //                    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        //                        [button setCenter:^ (CGFloat radians) {
        //                            return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
        //                        }(degreesToRadians(rescale(index, 0.0, 4.0, 180.0 - angle_adj, 270.0 - angle_adj)))];
        //                    });
        //                });
        ////                [display_link invalidate]; // test -- remove
        //                return (long)1;
        //            };
        //        }));
        //        return (long)1;
        //    };
        highlighted_property_bit_vector = MASK_NONE;
    });
    
    dispatch_barrier_async(enumerator_queue(), ^{ touch_handler(nil); /* the torch-level button does not position correctly when the control returns to the primary state */ });
    
    return (long)1;
};

static void (^draw_tick_wheel)(CGContextRef, CGRect);
static void (^(^draw_tick_wheel_init)(ControlView *, CGFloat *, CGFloat *))(CGContextRef, CGRect) = ^ (ControlView * view, CGFloat * touch_angle, CGFloat * radius) {
    return ^ (CGContextRef ctx, CGRect rect) {
        dispatch_barrier_sync(enumerator_queue(), ^{
            ((active_component_bit_vector & MASK_ALL) && ^ long (void) {
                CGContextClearRect(ctx, rect);
                
                return active_component_bit_vector;
            }())
            
            ||
            
            ((active_component_bit_vector & ~MASK_ALL) && ^ long (void) {
                UIGraphicsBeginImageContextWithOptions(rect.size, FALSE, 1.0);
                CGContextTranslateCTM(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
                for (unsigned int t = 180; t <= 270; t++) {
                    CGFloat angle = degreesToRadians(t);
                    CGFloat tick_height = (t == 180 || t == 270) ? 9.0 : (t % (unsigned int)round((270 - 180) / 9.0) == 0) ? 6.0 : 3.0;
                    {
                        CGPoint xy_outer = CGPointMake(((*radius + tick_height) * cosf(angle)),
                                                       ((*radius + tick_height) * sinf(angle)));
                        CGPoint xy_inner = CGPointMake(((*radius - tick_height) * cosf(angle)),
                                                       ((*radius - tick_height) * sinf(angle)));
                        CGContextSetStrokeColorWithColor(ctx, (t <= *touch_angle) ? [[UIColor systemGreenColor] CGColor] : [[UIColor systemRedColor] CGColor]);
                        CGContextSetLineWidth(ctx, (t == 180 || t == 270) ? 2.0 : (t % 9 == 0) ? 1.0 : 0.625);
                        CGContextMoveToPoint(ctx, xy_outer.x + CGRectGetMaxX(rect), xy_outer.y + CGRectGetMaxY(rect));
                        CGContextAddLineToPoint(ctx, xy_inner.x + CGRectGetMaxX(rect), xy_inner.y + CGRectGetMaxY(rect));
                    }
                    CGContextStrokePath(ctx);
                }
                UIGraphicsEndImageContext();
                [(ControlView *)view setNeedsDisplay];
                
                return active_component_bit_vector;
            }());
        });
    };
};

static void (^(^touch_handler)(__strong UITouch * _Nullable))(long (^ _Nullable /* set_state (for this handle_touch) */)(void (^ _Nonnull /* handle_touch (for set_state) */)(long (^ _Nullable /* set_state (a placeholder for handle_touch in this case) */)(void))));
static void (^handle_touch)(long (^ _Nullable /* set_state (for this handle_touch) */)(void (^ _Nonnull /* handle_touch (for set_state) */)(long (^ _Nullable /* set_state (a placeholder for handle_touch in this case) */)(void))));
static void (^(^(^touch_handler_init)(ControlView *, id<CaptureDeviceConfigurationControlPropertyDelegate>))(__strong UITouch * _Nullable))(long (^ _Nullable /* set_state (for this handle_touch) */)(void (^ _Nonnull /* handle_touch (for set_state) */)(long (^ _Nullable /* set_state (a placeholder for handle_touch in this case) */)(void)))) =  ^ (ControlView * view, id<CaptureDeviceConfigurationControlPropertyDelegate> delegate) {
    CGPoint center_point = CGPointMake(CGRectGetMaxX(((ControlView *)view).bounds), CGRectGetMaxY(((ControlView *)view).bounds));
    static CGFloat touch_angle;
    static CGPoint touch_point;
    static CGFloat radius;
    draw_tick_wheel = draw_tick_wheel_init((ControlView *)view, &touch_angle, &radius);
    return ^ (__strong UITouch * _Nullable touch) {
        return ^ (long (^ _Nullable state_setter)(void (^ _Nonnull /* handle_touch (for set_state) */)(long (^ _Nullable /* set_state (a placeholder for handle_touch in this case) */)(void)))) {
//            dispatch_barrier_sync(enumerator_queue(), ^{
                touch_point = [touch locationInView:(ControlView *)view];
                touch_point.x = fmaxf(0.0, fminf(touch_point.x, CGRectGetMaxX(((ControlView *)view).bounds)));
                touch_point.y = fmaxf(0.0, fminf(touch_point.y, CGRectGetMaxY(((ControlView *)view).bounds)));
                
                touch_angle = (atan2((touch_point).y - (center_point).y, (touch_point).x - (center_point).x)) * (180.0 / M_PI);
                if (touch_angle < 0.0) touch_angle += 360.0;
                touch_angle = fmaxf(180.0, fminf(touch_angle, 270.0));
                
                radius = fmaxf(CGRectGetMidX(((ControlView *)view).bounds),
                               fminf((sqrt(pow(touch_point.x - center_point.x, 2.0) + pow(touch_point.y - center_point.y, 2.0))),
                                     CGRectGetMaxX(((ControlView *)view).bounds)));
                
                highlighted_property_bit_vector = (((active_component_bit_vector & MASK_ALL) & 1UL) << ((unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0))));
//            });
            
//            dispatch_barrier_sync(enumerator_queue(), ^{
                ((active_component_bit_vector & MASK_ALL)
                 && filter(buttons)(^ (ControlView * view, CGFloat * r) {
                    return ^ (UIButton * _Nonnull button, unsigned int index) {
                        dispatch_barrier_async(dispatch_get_main_queue(), ^{
                            //                            [button setHighlighted:((active_component_bit_vector >> index) & 1UL) & (UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ index) & ((highlighted_property_bit_vector >> index) & 1UL)];
                            [button setCenter:^ (CGFloat radians) {
                                return CGPointMake(center_point.x - *r * -cos(radians), center_point.y - *r * -sin(radians));
                            }(degreesToRadians(rescale(index, 0.0, 4.0, 180.0, 270.0)))];
                        });
                    };
                }((ControlView *)view, &radius)))
                || ((active_component_bit_vector & ~MASK_ALL)
                    && reduce(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                    dispatch_barrier_async(dispatch_get_main_queue(), ^{
                        [button setCenter:^ (CGFloat radians) {
                            return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
                        }(degreesToRadians(touch_angle))];
                    });
                    
                    if (index == CaptureDeviceConfigurationControlPropertyVideoZoomFactor)
                        [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat videoZoomFactor){
                            return ^ (AVCaptureDevice * capture_device) {
                                [capture_device setVideoZoomFactor:videoZoomFactor];
                            };
                        }(rescale(touch_angle, 180.0, 270.0, 1.0, 9.0))];
                    else if (index == CaptureDeviceConfigurationControlPropertyLensPosition)
                        [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat lensPosition){
                            return ^ (AVCaptureDevice * capture_device) {
                                [capture_device setFocusModeLockedWithLensPosition:lensPosition completionHandler:nil];
                            };
                        }(rescale(touch_angle, 180.0, 270.0, 0.0, 1.0))];
                    else if (index == CaptureDeviceConfigurationControlPropertyTorchLevel)
                        [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat torchLevel){
                            return ^ (AVCaptureDevice * capture_device) {
                                __autoreleasing NSError * error = nil;
                                if (([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
                                    if (torchLevel != 0)
                                        [capture_device setTorchModeOnWithLevel:torchLevel error:&error];
                                    else
                                        [capture_device setTorchMode:AVCaptureTorchModeOff];
                                }
                            };
                        }(rescale(touch_angle, 180.0, 270.0, 0.0, 1.0))];
                    else if (index == CaptureDeviceConfigurationControlPropertyISO)
                        [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat ISO){
                            return ^ (AVCaptureDevice * capture_device) {
                                [capture_device setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:nil];
                            };
                        }(rescale(touch_angle, 180.0, 270.0, [delegate minISO_], [delegate maxISO_]))];
                    else if (index == CaptureDeviceConfigurationControlPropertyExposureDuration)
                        [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat exposureDuration){
                            return ^ (AVCaptureDevice * capture_device) {
                                static const float kExposureDurationPower = 5;
                                static const float kExposureMinimumDuration = 1.0/1000;
                                double p = pow( exposureDuration, kExposureDurationPower ); // Apply power function to expand slider's low-end range
                                double minDurationSeconds = MAX( CMTimeGetSeconds(capture_device.activeFormat.minExposureDuration ), kExposureMinimumDuration );
                                double maxDurationSeconds = 1.0/3.0;//CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
                                double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
                                [capture_device setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
                            };
                        }(rescale(touch_angle, 180.0, 270.0, 0.0, 1.0))];
                }));
                [((ControlView *)view) setNeedsDisplay];
//            });
            
//            dispatch_barrier_sync(enumerator_queue(), ^{
            ((long)0 || state_setter) && state_setter(^ (long (^ _Nullable set_state)(void)) {
                    ((active_component_bit_vector & MASK_ALL)
                     && filter(buttons)(^ (ControlView * view, CGFloat * r) {
                        return ^ (UIButton * _Nonnull button, unsigned int index) {
                            dispatch_barrier_async(dispatch_get_main_queue(), ^{
                                //                            [button setHighlighted:((active_component_bit_vector >> index) & 1UL) & (UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ index) & ((highlighted_property_bit_vector >> index) & 1UL)];
                                [button setCenter:^ (CGFloat radians) {
                                    return CGPointMake(center_point.x - *r * -cos(radians), center_point.y - *r * -sin(radians));
                                }(degreesToRadians(rescale(index, 0.0, 4.0, 180.0, 270.0)))];
                            });
                        };
                    }((ControlView *)view, &radius)))
                    || ((active_component_bit_vector & ~MASK_ALL)
                        && reduce(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                        dispatch_barrier_async(dispatch_get_main_queue(), ^{
                            [button setCenter:^ (CGFloat radians) {
                                return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
                            }(degreesToRadians(touch_angle))];
                        });
                        
                        if (index == CaptureDeviceConfigurationControlPropertyVideoZoomFactor)
                            [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat videoZoomFactor){
                                return ^ (AVCaptureDevice * capture_device) {
                                    [capture_device setVideoZoomFactor:videoZoomFactor];
                                };
                            }(rescale(touch_angle, 180.0, 270.0, 1.0, 9.0))];
                        else if (index == CaptureDeviceConfigurationControlPropertyLensPosition)
                            [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat lensPosition){
                                return ^ (AVCaptureDevice * capture_device) {
                                    [capture_device setFocusModeLockedWithLensPosition:lensPosition completionHandler:nil];
                                };
                            }(rescale(touch_angle, 180.0, 270.0, 0.0, 1.0))];
                        else if (index == CaptureDeviceConfigurationControlPropertyTorchLevel)
                            [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat torchLevel){
                                return ^ (AVCaptureDevice * capture_device) {
                                    __autoreleasing NSError * error = nil;
                                    if (([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
                                        if (torchLevel != 0)
                                            [capture_device setTorchModeOnWithLevel:torchLevel error:&error];
                                        else
                                            [capture_device setTorchMode:AVCaptureTorchModeOff];
                                    }
                                };
                            }(rescale(touch_angle, 180.0, 270.0, 0.0, 1.0))];
                        else if (index == CaptureDeviceConfigurationControlPropertyISO)
                            [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat ISO){
                                return ^ (AVCaptureDevice * capture_device) {
                                    [capture_device setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:nil];
                                };
                            }(rescale(touch_angle, 180.0, 270.0, [delegate minISO_], [delegate maxISO_]))];
                        else if (index == CaptureDeviceConfigurationControlPropertyExposureDuration)
                            [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat exposureDuration){
                                return ^ (AVCaptureDevice * capture_device) {
                                    static const float kExposureDurationPower = 5;
                                    static const float kExposureMinimumDuration = 1.0/1000;
                                    double p = pow( exposureDuration, kExposureDurationPower ); // Apply power function to expand slider's low-end range
                                    double minDurationSeconds = MAX( CMTimeGetSeconds(capture_device.activeFormat.minExposureDuration ), kExposureMinimumDuration );
                                    double maxDurationSeconds = 1.0/3.0;//CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
                                    double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
                                    [capture_device setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
                                };
                            }(rescale(touch_angle, 180.0, 270.0, 0.0, 1.0))];
                    }));
//                });
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [((ControlView *)view) setNeedsDisplay];
                    });
            });
            
            //            dispatch_barrier_sync(enumerator_queue(), ^{
            //                ((long)0 || transition) && transition(center_point, radius); //set_button_state((unsigned int)round(fmaxf(0.0, fminf((unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0)), 4.0))))(center_point, radius);
            //                ((active_component_bit_vector & MASK_ALL)
            //                 && filter(buttons)(^ (ControlView * view, CGFloat * r) {
            //                    return ^ (UIButton * _Nonnull button, unsigned int index) {
            //                        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            //                            //                            [button setHighlighted:((active_component_bit_vector >> index) & 1UL) & (UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ index) & ((highlighted_property_bit_vector >> index) & 1UL)];
            //                            [button setCenter:^ (CGFloat radians) {
            //                                return CGPointMake(center_point.x - *r * -cos(radians), center_point.y - *r * -sin(radians));
            //                            }(degreesToRadians(rescale(index, 0.0, 4.0, 180.0, 270.0)))]; // Consider using touch_property or index * (270 - 180) / 4 instead of rescaling
            //                        });
            //                    };
            //                }((ControlView *)view, &radius)))
            //                || ((active_component_bit_vector & ~MASK_ALL)
            //                    && reduce(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
            //                    dispatch_barrier_async(dispatch_get_main_queue(), ^{
            //                        [button setCenter:^ (CGFloat radians) {
            //                            return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
            //                        }(degreesToRadians(touch_angle))];
            //                    });
            //                }));
            //            });
//            [((ControlView *)view) setNeedsDisplay];
        };
    };
};


@implementation ControlView {
        UISelectionFeedbackGenerator * haptic_feedback;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.layer setAffineTransform:CGAffineTransformMakeRotation(degreesToRadians(360.0))];
    [self.layer setAffineTransform:CGAffineTransformScale(self.layer.affineTransform, -1, -1)];
    
    [self updateStateLabels];
        haptic_feedback = [[UISelectionFeedbackGenerator alloc] init];
        [haptic_feedback prepare];
    
    CGPoint default_center_point = CGPointMake(CGRectGetMaxX(((ControlView *)self).bounds), CGRectGetMaxY(((ControlView *)self).bounds));
    CGFloat default_radius       = CGRectGetMidX(self.bounds);
    
    map(buttons)(^ UIButton * (unsigned int index) {
        UIButton * button;
        [button = [UIButton new] setTag:index];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[0][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateDeselected)] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateSelected)] forState:UIControlStateSelected];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateHighlighted)] forState:UIControlStateHighlighted];
        
        //        [button setTitle:[NSString stringWithFormat:@"%lu - %lu",
        //                          (Log2n(selected_property_bit_vector)), (Log2n(highlighted_property_bit_vector))] forState:UIControlStateNormal];
        
        
        [button sizeToFit];
        
        CGFloat angle = rescale(index, 0.0, 4.0, 180.0, 270.0);
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
        [self addSubview:button];
        angle = degreesToRadians(angle);
        [button setCenter:[[UIBezierPath bezierPathWithArcCenter:default_center_point radius:default_radius startAngle:angle endAngle:angle clockwise:FALSE] currentPoint]];
        return button;
    });
    
    touch_handler = touch_handler_init((ControlView *)self, self.captureDeviceConfigurationControlPropertyDelegate); // touch_handler_init(self, self.captureDeviceConfigurationControlPropertyDelegate);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_sync(enumerator_queue(), ^{ (handle_touch = touch_handler(touches.anyObject))(nil); });
    dispatch_barrier_sync(enumerator_queue(), ^{ [self updateStateLabels]; });
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_sync(enumerator_queue(), ^{ handle_touch(nil); });
    dispatch_barrier_sync(enumerator_queue(), ^{ [self updateStateLabels]; });
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_sync(enumerator_queue(), ^{ handle_touch(set_state); });
    dispatch_barrier_sync(enumerator_queue(), ^{ [self updateStateLabels]; });
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_sync(enumerator_queue(), ^{
        [self setUserInteractionEnabled:FALSE];
    });
    dispatch_barrier_sync(enumerator_queue(), ^{
        handle_touch(set_state);
    });
    dispatch_barrier_sync(enumerator_queue(), ^{
        [self setUserInteractionEnabled:TRUE];
    });
}

- (void)drawRect:(CGRect)rect {
    draw_tick_wheel(UIGraphicsGetCurrentContext(), rect);
    // To-Do: only "click" when a new value is selected - not every time drawRect is called
        [haptic_feedback selectionChanged];
        [haptic_feedback prepare];
}

- (void)updateStateLabels {
    [self.stateBitVectorLabel setText:NSStringFromBitVector(active_component_bit_vector, 5)];
    [self.highlightedBitVectorLabel setText:NSStringFromBitVector(highlighted_property_bit_vector, 5)];
    [self.selectedBitVectorLabel setText:NSStringFromBitVector(selected_property_bit_vector, 5)];
    [self.hiddenBitVectorLabel setText:NSStringFromBitVector(hidden_property_bit_vector, 5)];
}

@end
