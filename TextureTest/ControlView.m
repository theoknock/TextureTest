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
static uint8_t active_component_bit_vector  = MASK_ALL;
static uint8_t selected_property_bit_vector = MASK_NONE;
static uint8_t hidden_property_bit_vector   = MASK_NONE;

static dispatch_queue_t enumerator_queue() {
    static dispatch_queue_t sl_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sl_queue = dispatch_queue_create("com.somnus.xxx", NULL);
    });
    
    return sl_queue;
};

static __strong UIButton * _Nonnull buttons[5];
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

static long (^Log2n)(unsigned int) = ^ long (unsigned int bit_field) {
    return (bit_field > 1) ? 1 + Log2n(bit_field / 2) : 0;
};

static long (^(^integrate)(long))(void(^__strong)(long)) = ^ (long duration) {
    __block long frames = ~(1 << (duration + 1));
    return ^ long (void (^__strong integrand)(long)) {
        dispatch_barrier_async(enumerator_queue(), ^{
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_APPLY_AUTO);
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, (1.0/duration) * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            frames >>= 1;

            ((frames & 1) &&
             ^ long {
                integrand(Log2n(frames));
                return active_component_bit_vector;
            }())
            
            ||
            
            ((frames | 1) &&
             ^ long {
                printf("animation end\n");
                dispatch_suspend(timer);
                return active_component_bit_vector;
            }());
        });
        
            dispatch_resume(timer);
        });
        printf("animation begin\t\t\t---------------\t\t\t");

        return active_component_bit_vector;
    };
};


//static long (^(^integrate)(long))(void(^__strong)(long)) = ^ (long duration) {
//    __block typeof(CADisplayLink *) display_link;
//    __block long frames = ~(1 << (duration + 1));
//    return ^ long (void (^__strong integrand)(long)) {
//        printf("animation begin\t\t\t---------------\t\t\t");
//        display_link = [CADisplayLink displayLinkWithTarget:^{
//            frames >>= 1;
//            return
//            ((frames & 1) &&
//             ^ long {
//                integrand(Log2n(frames));
//                return active_component_bit_vector;
//            }())
//
//            ||
//
//            ((frames | 1) &&
//             ^ long {
//                printf("animation end\n");
//                [display_link invalidate];
//                return active_component_bit_vector;
//            }());
//        } selector:@selector(invoke)];
//        [display_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//        return active_component_bit_vector;
//    };
//};

static uint8_t (^(^filter)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    return ^ uint8_t (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
        dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t index) {
            dispatch_barrier_async(dispatch_get_main_queue(), ^{
                [button_collection[index] setSelected:(selected_property_bit_vector >> index) & 1UL];
                [button_collection[index] setHidden:(hidden_property_bit_vector >> index) & 1UL];
            });
            enumeration(button_collection[index], (unsigned int)index);
        });
        return active_component_bit_vector;
    };
};

static long (^(^reduce)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    return ^ long (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
        unsigned int selected_property_bit_position = (Log2n(selected_property_bit_vector));
        enumeration(button_collection[selected_property_bit_position], (unsigned int)selected_property_bit_position);
        return active_component_bit_vector;
    };
};

long (^(^set_state)(unsigned int))(CGPoint, CGFloat) = ^ (unsigned int touch_property) {
    active_component_bit_vector = ~active_component_bit_vector;
    // converse nonimplication
    uint8_t selected_property_bit_mask = MASK_NONE;
    selected_property_bit_mask ^= (1UL << touch_property) & ~active_component_bit_vector;
    selected_property_bit_vector = (selected_property_bit_vector | selected_property_bit_mask) & ~selected_property_bit_vector;
    
    // exclusive disjunction
    hidden_property_bit_vector = ~active_component_bit_vector;
    hidden_property_bit_vector = selected_property_bit_mask & ~active_component_bit_vector;
    hidden_property_bit_vector ^= MASK_ALL;
    hidden_property_bit_vector ^= active_component_bit_vector;
    
    return ^ long (CGPoint center_point, CGFloat radius) {
            ((active_component_bit_vector & MASK_ALL) &&
             
             integrate((long)30)(^ (long frame) {
                CGFloat angle_adj = (360.0 / 30.0) * frame;
                filter(buttons)(^{
                    return ^ (UIButton * _Nonnull button, unsigned int index) {
                        dispatch_barrier_async(dispatch_get_main_queue(), ^{
                        [button setCenter:^ (CGFloat radians) {
                            return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
                        }(degreesToRadians(rescale(button.tag, 0.0, 4.0, 180.0 + angle_adj, 270.0 + angle_adj)))];
                        });
                    };
                }());
            }))
            
            ||
            
            ((active_component_bit_vector & ~MASK_ALL) &&
             
             integrate((long)30)(^ (long frame) {
                CGFloat angle_adj = (360.0 / 30.0) * frame;
                reduce(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                    dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    [button setCenter:^ (CGFloat radians) {
                        return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
                    }(degreesToRadians(rescale(button.tag, 0.0, 4.0, 180.0 - angle_adj, 270.0 - angle_adj)))];
                    });
                });
            }));
        return (long)1;
    };
};


static void (^draw_tick_wheel)(CGContextRef, CGRect);
static void (^(^draw_tick_wheel_init)(ControlView *, CGFloat *, CGFloat *))(CGContextRef, CGRect) = ^ (ControlView * view, CGFloat * touch_angle, CGFloat * radius) {
    return ^ (CGContextRef ctx, CGRect rect) {
        dispatch_barrier_sync(enumerator_queue(), ^{
            ((active_component_bit_vector & MASK_ALL) &&
             
             ^ long (void) {
                //            //printf("Clearing context...\n");
                CGContextClearRect(ctx, rect);
                
                return active_component_bit_vector;
            }())
            
            ||
            
            ((active_component_bit_vector & ~MASK_ALL) &&
             
             ^ long (void) {
                //            //printf("Rendering context...\n");
                UIGraphicsBeginImageContextWithOptions(rect.size, FALSE, 1.0);
                //            CGContextRef ctx = UIGraphicsGetCurrentContext();
                CGContextTranslateCTM(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
                
                //            float multiplier  = (*radius / 2.0) / CGRectGetMaxX(view.frame);
                //            unsigned int step = (unsigned int)round(((270.0 - 180.0) / multiplier) / (270.0 - 180.0));
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
                //                    CGContextClip(ctx);
                UIGraphicsEndImageContext();
                //        UIGraphicsPushContext(ctx);
                //        [(ControlView *)view drawRect:rect];
                // UIGraphicsPopContext();
                //
                
                // FOURTH dispatch_barrier_sync?
                [(ControlView *)view setNeedsDisplay];
                return active_component_bit_vector;
            }());
        });
    };
};

static void (^(^touch_handler)(__strong UITouch * _Nullable))(long (^(^)(unsigned int))(CGPoint, CGFloat));
static void (^handle_touch)(long (^(^)(unsigned int))(CGPoint, CGFloat));
static void (^(^(^touch_handler_init)(ControlView *, id<CaptureDeviceConfigurationControlPropertyDelegate>))(__strong UITouch * _Nullable))(long (^(^)(unsigned int))(CGPoint, CGFloat)) =  ^ (ControlView * view, id<CaptureDeviceConfigurationControlPropertyDelegate> delegate) {
    CGPoint center_point = CGPointMake(CGRectGetMaxX(((ControlView *)view).bounds), CGRectGetMaxY(((ControlView *)view).bounds));
    static CGFloat touch_angle;
    static CGPoint touch_point;
    static CGFloat radius;
    draw_tick_wheel = draw_tick_wheel_init((ControlView *)view, &touch_angle, &radius);
    return ^ (__strong UITouch * _Nullable touch) {
        return ^ (long (^(^ _Nullable set_button_state)(unsigned int))(CGPoint, CGFloat)) {
            /*
             FIRST DISPATCH QUEUE BARRIER (OUT OF FOUR)
             */
            dispatch_barrier_sync(enumerator_queue(), ^{
                
                
                touch_point = [touch locationInView:(ControlView *)view];
                touch_point.x = fmaxf(0.0,
                                      fminf(touch_point.x,
                                            CGRectGetMaxX(((ControlView *)view).bounds)));
                touch_point.y = fmaxf(0.0,
                                      fminf(touch_point.y,
                                            CGRectGetMaxY(((ControlView *)view).bounds)));
                touch_angle = (atan2((touch_point).y - (center_point).y,
                                     (touch_point).x - (center_point).x)) * (180.0 / M_PI);
                if (touch_angle < 0.0) touch_angle += 360.0;
                touch_angle = fmaxf(180.0,
                                    fminf(touch_angle,
                                          270.0));
                
                radius = fmaxf(CGRectGetMidX(((ControlView *)view).bounds),
                               fminf((sqrt(pow(touch_point.x - center_point.x, 2.0) + pow(touch_point.y - center_point.y, 2.0))),
                                     CGRectGetMaxX(((ControlView *)view).bounds)));
            });
                /*
                 SECOND DISPATCH QUEUE BARRIER (OUT OF FOUR)
                 */
                dispatch_barrier_sync(enumerator_queue(), ^{
                    ((long)0 || set_button_state) && set_button_state((unsigned int)round(fmaxf(0.0,
                                                                                                fminf((unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0)),
                                                                                                      4.0))))(center_point, radius);
                });
            
            
            /*
             THIRD DISPATCH QUEUE BARRIER (OUT OF FOUR)
             */
            dispatch_barrier_sync(enumerator_queue(), ^{
                
                
                ((active_component_bit_vector & MASK_ALL)
                 && filter(buttons)(^ (ControlView * view, CGFloat * r) {
                    unsigned int touch_property = (unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0));
                    return ^ (UIButton * _Nonnull button, unsigned int index) {  // Consider comparing index to button.tag instead of touch_property to button.tag
                        dispatch_barrier_async(dispatch_get_main_queue(), ^{
                        [button setHighlighted:((active_component_bit_vector >> button.tag) & 1UL) & (UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                        [button setCenter:^ (CGFloat radians) {
                            return CGPointMake(center_point.x - *r * -cos(radians), center_point.y - *r * -sin(radians));
                        }(degreesToRadians(rescale(button.tag, 0.0, 4.0, 180.0, 270.0)))]; // Consider using touch_property or index * (270 - 180) / 4 instead of rescaling
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
                    
                    if (button.tag == CaptureDeviceConfigurationControlPropertyVideoZoomFactor)
                        [delegate setCaptureDeviceConfigurationControlPropertyUsingBlock:^ (CGFloat videoZoomFactor){
                            return ^ (AVCaptureDevice * capture_device) {
                                [capture_device setVideoZoomFactor:videoZoomFactor];
                            };
                        }(rescale(touch_angle, 180.0, 270.0, 1.0, 9.0))];
                    else if (button.tag == CaptureDeviceConfigurationControlPropertyLensPosition)
                        [delegate setLensPosition_:(rescale(touch_angle, 180.0, 270.0, 0.0, 1.0))];
                    else if (button.tag == CaptureDeviceConfigurationControlPropertyTorchLevel)
                        [delegate setTorchLevel_:rescale(touch_angle, 180.0, 270.0, 0.0, 1.0)];
                    else if (button.tag == CaptureDeviceConfigurationControlPropertyISO)
                        [delegate setISO_:rescale(touch_angle, 180.0, 270.0, [delegate minISO_], [delegate maxISO_])];
                    else if (button.tag == CaptureDeviceConfigurationControlPropertyExposureDuration)
                        [delegate setExposureDuration_:rescale(touch_angle, 180.0, 270.0, 0.0, 1.0)];
                    [((ControlView *)view) setNeedsDisplay];
                }));
            });
        };
        
    };
};

static NSString * (^NSStringFromBitVector)(uint8_t) = ^ NSString * (uint8_t bit_vector) {
    NSMutableString * bit_vector_str = [[NSMutableString alloc] initWithCapacity:5];
    for (int i = sizeof(char) * 4; i >= 0; i--)
        [bit_vector_str appendString:[NSString stringWithFormat:@"%d", (bit_vector & (1 << i)) >> i]];
    return (NSString *)bit_vector_str;
};


@implementation ControlView {
    UISelectionFeedbackGenerator * haptic_feedback;
}



- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.stateBitVectorLabel setText:[NSString stringWithFormat:@"%@", (active_component_bit_vector == MASK_ALL) ? @"11111" : @"00000"]];
    [self.selectedBitVectorLabel setText:NSStringFromBitVector(selected_property_bit_vector)];
    [self.hiddenBitVectorLabel setText:NSStringFromBitVector(hidden_property_bit_vector)];
    
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
        
        //        [button setTitle:[NSString stringWithFormat:@"%d - %d",
        //                                       (Log2n(selected_property_bit_vector)), (Log2n(hidden_property_bit_vector))] forState:UIControlStateNormal];
        
        
        [button sizeToFit];
        
        CGFloat angle = rescale(index, 0.0, 4.0, 180.0, 270.0);
        NSNumber * button_angle = [NSNumber numberWithFloat:angle];
        objc_setAssociatedObject (button,
                                  (void *)button.tag,
                                  button_angle,
                                  OBJC_ASSOCIATION_RETAIN);
        
        [button setUserInteractionEnabled:FALSE];
        void (^eventHandlerBlockTouchUpInside)(void) = ^{
            NSNumber * associatedObject = (NSNumber *)objc_getAssociatedObject (button, (void *)button.tag);
            //printf("%s\n", [[associatedObject stringValue] UTF8String]);
        };
        objc_setAssociatedObject(button, @selector(invoke), eventHandlerBlockTouchUpInside, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [button addTarget:eventHandlerBlockTouchUpInside action:@selector(invoke) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        angle = degreesToRadians(angle);
        [button setCenter:[[UIBezierPath bezierPathWithArcCenter:default_center_point radius:default_radius startAngle:angle endAngle:angle clockwise:FALSE] currentPoint]];
        return button;
    });
    
    touch_handler = touch_handler_init(self, self.captureDeviceConfigurationControlPropertyDelegate);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        (handle_touch = touch_handler(touches.anyObject))(nil);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        handle_touch(nil);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        handle_touch(set_state);
    
    dispatch_barrier_sync(enumerator_queue(), ^{
        [self.stateBitVectorLabel setText:[NSString stringWithFormat:@"%@", (active_component_bit_vector == MASK_ALL) ? @"11111" : @"00000"]];
        [self.selectedBitVectorLabel setText:NSStringFromBitVector(selected_property_bit_vector)];
        [self.hiddenBitVectorLabel setText:NSStringFromBitVector(hidden_property_bit_vector)];
    });
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    handle_touch(set_state);
}

- (void)drawRect:(CGRect)rect {
    draw_tick_wheel(UIGraphicsGetCurrentContext(), rect);
    // To-Do: only "click" when a new value is selected - not every time drawRect is called
    [haptic_feedback selectionChanged];
    [haptic_feedback prepare];
}

@end
