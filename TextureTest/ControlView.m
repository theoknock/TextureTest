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
    
    // converse nonimplication
    uint8_t selected_property_bit_mask = MASK_NONE;
    selected_property_bit_mask ^= (1UL << touch_property) & ~active_component_bit_vector;
    selected_property_bit_vector = (selected_property_bit_vector | selected_property_bit_mask) & ~selected_property_bit_vector;
    
    // exclusive disjunction
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

static unsigned int (^Log2n)(unsigned int) = ^ unsigned int (unsigned int bit_field) {
    return (bit_field > 1) ? 1 + Log2n(bit_field / 2) : 0;
};

static long (^(^reduce)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    return ^ (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    unsigned int selected_property_bit_position = (Log2n(selected_property_bit_vector));
//                    printf("selected_property_bit_position == %d\n", selected_property_bit_position);
                    enumeration(button_collection[selected_property_bit_position], (unsigned int)selected_property_bit_position);
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
static void (^(^(^touch_handler_init)(ControlView *, UILabel *))(UITouch *))(void(^ _Nullable)(unsigned int)) =  ^ (ControlView * view, UILabel * property_value_label) {
    CGPoint center_point = CGPointMake(CGRectGetMaxX(((ControlView *)view).bounds), CGRectGetMaxY(((ControlView *)view).bounds));
    return ^ (UITouch * touch) {
        
        return ^ (void(^ _Nullable set_button_state)(unsigned int)) {
            static CGFloat touch_angle;
            static CGPoint touch_point;
            static CGFloat radius; // calculated as the square root of the sum of the squares of its two values
            static unsigned int touch_property;
            touch_point = [touch preciseLocationInView:(ControlView *)view];
            radius = fmaxf(CGRectGetMidX(((ControlView *)view).bounds),
                           fminf((sqrt(pow(touch_point.x - center_point.x, 2.0) + pow(touch_point.y - center_point.y, 2.0))),
                                 CGRectGetMaxX(((ControlView *)view).bounds)));
            touch_angle = fmaxf(180.0,
                                fminf(atan2(touch_point.y - center_point.y, touch_point.x - center_point.x) * (180.0 / M_PI) + 360.0,
                                      270.0));
            touch_property = (unsigned int)round(fmaxf(0.0,
                                                       fminf((unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0)),
                                                             4.0)));
            if (set_button_state != nil) set_button_state(touch_property);

//            ((active_component_bit_vector & MASK_ALL) && printf("filter\t%f\n", touch_angle)) || printf("reduce\t%f\n", touch_angle);
            
            ((active_component_bit_vector & MASK_ALL) &&
             filter(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [button setHighlighted:((active_component_bit_vector >> button.tag) & 1UL) & (UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                [button setCenter:^ (CGFloat radians) {
                    return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
                }(degreesToRadians(rescale(button.tag, 0.0, 4.0, 180.0, 270.0)))];
            })) || reduce(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [button setCenter:^ (CGFloat radians) {
                    UIGraphicsBeginImageContextWithOptions(((ControlView *)view).bounds.size, FALSE, 1.0);
                    {
                        CGContextRef ctx = UIGraphicsGetCurrentContext();
                        CGContextTranslateCTM(ctx, CGRectGetMinX(((ControlView *)view).bounds), CGRectGetMinY(((ControlView *)view).bounds));
                        
                        for (unsigned int t = 180; t <= 270; t++) {
                            CGFloat angle = degreesToRadians(t);
                            CGFloat tick_height = (t == 180 || t == 270) ? 10.0 : (t % (unsigned int)round((270 - 180) / 10) == 0) ? 6.0 : 3.0;
                            {
                                CGPoint xy_outer = CGPointMake(((radius + tick_height) * cosf(angle)),
                                                               ((radius + tick_height) * sinf(angle)));
                                CGPoint xy_inner = CGPointMake(((radius - tick_height) * cosf(angle)),
                                                               ((radius - tick_height) * sinf(angle)));
                                CGContextSetStrokeColorWithColor(ctx, (t <= angle) ? [[UIColor systemGreenColor] CGColor] : [[UIColor systemRedColor] CGColor]);
                                CGContextSetLineWidth(ctx, (t == 180 || t == 270) ? 2.0 : (t % 10 == 0) ? 1.0 : 0.625);
                                CGContextMoveToPoint(ctx, xy_outer.x + CGRectGetMaxX(((ControlView *)view).bounds), xy_outer.y + CGRectGetMaxY(((ControlView *)view).bounds));
                                CGContextAddLineToPoint(ctx, xy_inner.x + CGRectGetMaxX(((ControlView *)view).bounds), xy_inner.y + CGRectGetMaxY(((ControlView *)view).bounds));
                            }
                            CGContextStrokePath(ctx);
                        }
                    } UIGraphicsEndImageContext();
                    [view setNeedsDisplay];
                    
                    return CGPointMake(center_point.x - radius * -cos(radians), center_point.y - radius * -sin(radians));
                }(degreesToRadians(touch_angle))];
                
            });
        };
    };
};

@implementation ControlView {
    UISelectionFeedbackGenerator * haptic_feedback;
    NSDictionary* hapticDict;
    UILabel * property_value_label;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    property_value_label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.bounds), CGRectGetMidX(self.bounds), 175, 24)];
    property_value_label.text = @"---";
    property_value_label.textColor = [UIColor whiteColor];
    property_value_label.textAlignment = NSTextAlignmentCenter;
    property_value_label.font = [UIFont boldSystemFontOfSize:20];
    
    [self addSubview:property_value_label];

    haptic_feedback = [[UISelectionFeedbackGenerator alloc] init];
    [haptic_feedback prepare];
    
    touch_handler = touch_handler_init(self, property_value_label);
    
    map(buttons)(^ UIButton * (unsigned int index) {
        UIButton * button;
        [button = [UIButton new] setTag:index];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[0][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateDeselected)] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateSelected)] forState:UIControlStateSelected];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateHighlighted)] forState:UIControlStateHighlighted];
        [button sizeToFit];
        [button setUserInteractionEnabled:FALSE];
        
        CGFloat angle = rescale(index, 0.0, 4.0, 180.0, 270.0);
        printf("angle == %f\n", angle);
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
        angle = degreesToRadians(angle);
        [button setCenter:[[UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds)) radius:CGRectGetMidX(self.bounds) startAngle:angle endAngle:angle clockwise:FALSE] currentPoint]];
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

@end
