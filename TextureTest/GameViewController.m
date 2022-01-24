//
//  GameViewController.m
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import "GameViewController.h"
#import "Renderer.h"
#import <objc/runtime.h>
#include <simd/simd.h>
#include <stdio.h>
#include <math.h>

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
    CaptureDeviceConfigurationControlPropertyTorchLevel,
    CaptureDeviceConfigurationControlPropertyLensPosition,
    CaptureDeviceConfigurationControlPropertyExposureDuration,
    CaptureDeviceConfigurationControlPropertyISO,
    CaptureDeviceConfigurationControlPropertyZoomFactor
} CaptureDeviceConfigurationControlProperty;

typedef enum : NSUInteger {
    CaptureDeviceConfigurationControlStateDeselected,
    CaptureDeviceConfigurationControlStateSelected,
    CaptureDeviceConfigurationControlStateHighlighted
} CaptureDeviceConfigurationControlState;

static UIImageSymbolConfiguration * (^CaptureDeviceConfigurationControlPropertySymbolImageConfiguration)(CaptureDeviceConfigurationControlState) = ^ UIImageSymbolConfiguration * (CaptureDeviceConfigurationControlState state) {
    switch (state) {
        case CaptureDeviceConfigurationControlStateDeselected: {
            UIImageSymbolConfiguration * symbol_palette_colors = [UIImageSymbolConfiguration configurationWithPaletteColors:@[[UIColor yellowColor], [UIColor systemBlueColor], [UIColor clearColor]]]; // configurationWithHierarchicalColor:[UIColor colorWithRed:4/255 green:51/255 blue:255/255 alpha:1.0]];
            UIImageSymbolConfiguration * symbol_font_weight    = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightLight];
            UIImageSymbolConfiguration * symbol_font_size      = [UIImageSymbolConfiguration configurationWithPointSize:42.0 weight:UIImageSymbolWeightLight];
            UIImageSymbolConfiguration * symbol_configuration  = [symbol_font_size configurationByApplyingConfiguration:[symbol_palette_colors configurationByApplyingConfiguration:symbol_font_weight]];
            return symbol_configuration;
        }
            break;
            
        case CaptureDeviceConfigurationControlStateSelected: {
            UIImageSymbolConfiguration * symbol_palette_colors_selected = [UIImageSymbolConfiguration configurationWithPaletteColors:@[[UIColor yellowColor], [UIColor systemBlueColor], [UIColor systemBlueColor]]]; //configurationWithHierarchicalColor:[UIColor colorWithRed:255/255 green:252/255 blue:121/255 alpha:1.0]];
            UIImageSymbolConfiguration * symbol_font_weight_selected    = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightRegular];
            UIImageSymbolConfiguration * symbol_font_size_selected      = [UIImageSymbolConfiguration configurationWithPointSize:42.0 weight:UIImageSymbolWeightLight];
            UIImageSymbolConfiguration * symbol_configuration_selected  = [symbol_font_size_selected configurationByApplyingConfiguration:[symbol_palette_colors_selected configurationByApplyingConfiguration:symbol_font_weight_selected]];
            
            return symbol_configuration_selected;
        }
            
        case CaptureDeviceConfigurationControlStateHighlighted: {
            UIImageSymbolConfiguration * symbol_palette_colors_highlighted = [UIImageSymbolConfiguration configurationWithPaletteColors:@[[UIColor yellowColor], [UIColor clearColor], [UIColor yellowColor]]];
            UIImageSymbolConfiguration * symbol_font_weight_highlighted    = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightRegular];
            UIImageSymbolConfiguration * symbol_font_size_highlighted      = [UIImageSymbolConfiguration configurationWithPointSize:42.0 weight:UIImageSymbolWeightLight];
            UIImageSymbolConfiguration * symbol_configuration_highlighted  = [symbol_font_size_highlighted configurationByApplyingConfiguration:[symbol_palette_colors_highlighted configurationByApplyingConfiguration:symbol_font_weight_highlighted]];
            
            return symbol_configuration_highlighted;
        }
            break;
        default:
            return nil;
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

static float (^rescale)(float old_value, float old_min, float old_max, float new_min, float new_max) = ^(float old_value, float old_min, float old_max, float new_min, float new_max) {
    return (new_max - new_min) * (old_value - old_min) / (old_max - old_min) + new_min;
};

static  uint8_t         active_component_bit_vector      = (1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4);
static  uint8_t * const active_component_bit_vector_ptr  = &active_component_bit_vector;
static  uint8_t         selected_property_bit_vector     = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
static  uint8_t * const selected_property_bit_vector_ptr = &selected_property_bit_vector;
static  uint8_t         hidden_property_bit_vector       = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
static  uint8_t * const hidden_property_bit_vector_ptr   = &hidden_property_bit_vector;

static __strong UIButton * _Nonnull buttons[5];
static void (^(^map)(__strong UIButton * _Nonnull [_Nonnull 5]))(UIButton * (^__strong)(unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    dispatch_queue_t enumerator_queue  = dispatch_queue_create("enumerator_queue", DISPATCH_QUEUE_SERIAL);
    return ^ (UIButton *(^enumeration)(unsigned int)) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            dispatch_apply(5, enumerator_queue, ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    button_collection[index] = enumeration((unsigned int)index); // return value
                });
            });
        });
    };
};

static void (^(^filter)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    dispatch_queue_t enumerator_queue  = dispatch_queue_create("enumerator_queue", DISPATCH_QUEUE_SERIAL);
    return ^ (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            dispatch_apply(5, enumerator_queue, ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    [button_collection[index] setSelected:(selected_property_bit_vector >> index) & 1U];
                    [button_collection[index] setHidden:(hidden_property_bit_vector >> index) & 1U];
                    enumeration(button_collection[index], (unsigned int)index); // no return value
                });
            });
        });
    };
};

static void (^(^(^touch_handler_init_button_arc)(UIView *))(UITouch *))(void(^)(unsigned int)) = ^ (UIView * view) {
    CGRect contextRect = view.bounds;
    float minX = (float)CGRectGetMinX(contextRect);
    float midX = (float)CGRectGetMidX(contextRect);
    float mdnX = (float)(((int)midX & (int)minX) + (((int)midX ^ (int)minX) >> 1));
    float maxX = (float)CGRectGetMaxX(contextRect);
    float mdxX = (float)(((int)maxX & (int)midX) + (((int)maxX ^ (int)midX) >> 1));
    
    float minY = (float)CGRectGetMinY(contextRect);
    float midY = (float)CGRectGetMidY(contextRect);
    float mdnY = (float)(((int)midY & (int)minY) + (((int)midY ^ (int)minY) >> 1));
    float maxY = (float)CGRectGetMaxY(contextRect);
    float mdxY = (float)(((int)maxY & (int)midY) + (((int)maxY ^ (int)midY) >> 1));
    
    return ^ (UITouch * touch) {
        static CGPoint touch_point;
        static CGFloat touch_angle;
        static float radius;
        return ^ (void(^ _Nullable set_button_state)(unsigned int)) {
            touch_point = [touch preciseLocationInView:view];
            touch_angle = (atan2(touch_point.y - maxY, touch_point.x - maxX) * (180.0 / M_PI)) + 360.0;
            unsigned int touch_property = (unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0));
            if (set_button_state != nil) set_button_state(touch_property);
            filter(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [button setHighlighted:(UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                [button setCenter:^{
                    // To-Do: Choose between two values: the button's "group" angle and its "tick-wheel" angle
                    float angle  = ((active_component_bit_vector >> button.tag) & 1U) ? rescale(button.tag, 0.0, 4.0, 180.0, 270.0) : touch_angle;; //(((selected_property_bit_vector >> index) & 1) & (UITouchPhaseEnded ^ touch.phase)) ? rescale(index, 0.0, 4.0, 180.0, 270.0) : touch_angle;
                    float radians = degreesToRadians(angle);
                    radius = ((active_component_bit_vector >> button.tag) & 1U) ? sqrt(pow(touch_point.x - maxX, 2.0) +
                                                                                       pow(touch_point.y - maxY, 2.0)) : radius;
                    radius = fmaxf(midX, fminf(radius, maxX));
                    CGFloat x = maxX - radius * -cos(radians);
                    CGFloat y = maxY - radius * -sin(radians);
                    return CGPointMake(x, y);
                }()];
            });
        };
    };
};



static void (^(^(^touch_handler_init_tick_wheel)(UIView *))(UITouch *))(void(^)(unsigned int)) = ^ (UIView * view) {
    printf("%s\n", __PRETTY_FUNCTION__);
    CGRect contextRect = view.bounds;
    float minX = (float)CGRectGetMinX(contextRect);
    float midX = (float)CGRectGetMidX(contextRect);
    float mdnX = (float)(((int)midX & (int)minX) + (((int)midX ^ (int)minX) >> 1));
    float maxX = (float)CGRectGetMaxX(contextRect);
    float mdxX = (float)(((int)maxX & (int)midX) + (((int)maxX ^ (int)midX) >> 1));
    
    float minY = (float)CGRectGetMinY(contextRect);
    float midY = (float)CGRectGetMidY(contextRect);
    float mdnY = (float)(((int)midY & (int)minY) + (((int)midY ^ (int)minY) >> 1));
    float maxY = (float)CGRectGetMaxY(contextRect);
    float mdxY = (float)(((int)maxY & (int)midY) + (((int)maxY ^ (int)midY) >> 1));
    
    static float radius; // TO-DO: get the last computed radius from the previous touch handler
    return ^ (UITouch * touch) {
        printf("%s\n", __PRETTY_FUNCTION__);
        static CGPoint touch_point;
        static CGFloat touch_angle;
        return ^ (void(^ _Nullable set_button_state)(unsigned int)) {
            touch_point = [touch preciseLocationInView:view];
            touch_angle = (atan2(touch_point.y - maxY, touch_point.x - maxX) * (180.0 / M_PI)) + 360.0;
            unsigned int button_index = log2(*selected_property_bit_vector_ptr &(~(*selected_property_bit_vector_ptr-1)));
            if (set_button_state != nil) set_button_state(button_index);
            printf("%d\t\t%s\n", button_index, __PRETTY_FUNCTION__);
            dispatch_barrier_async(dispatch_get_main_queue(), ^{
                [buttons[button_index] setCenter:^{
                    radius = ((active_component_bit_vector >> button_index) & 1U) ? sqrt(pow(touch_point.x - maxX, 2.0) +
                                                                                       pow(touch_point.y - maxY, 2.0)) : radius;
                    radius = fmaxf(midX, fminf(radius, maxX));
                    float radians = degreesToRadians(touch_angle);
                    CGFloat x = maxX - radius * -cos(radians);
                    CGFloat y = maxY - radius * -sin(radians);
                    return CGPointMake(x, y);
                }()];
            });
            
        };
    };
};

static void (^(^(^touch_handler_init)(UIView *))(UITouch *))(void(^)(unsigned int));
static void (^(^touch_handler)(UITouch *))(void(^ _Nullable)(unsigned int));
static void (^handle_touch)(void(^ _Nullable)(unsigned int));

@implementation GameViewController
{
    MTKView *_view;
    Renderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    map(buttons)(^ UIButton * (unsigned int index) {
        UIButton * button;
        [button = [UIButton new] setTag:index];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[0][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateDeselected)] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateSelected)] forState:UIControlStateSelected];
        [button setImage:[UIImage systemImageNamed:CaptureDeviceConfigurationControlPropertyImageValues[1][index] withConfiguration:CaptureDeviceConfigurationControlPropertySymbolImageConfiguration(CaptureDeviceConfigurationControlStateHighlighted)] forState:UIControlStateHighlighted];
        [button sizeToFit];
        [button setUserInteractionEnabled:FALSE];
        void (^eventHandlerBlockTouchUpInside)(void) = ^{
            
        };
        objc_setAssociatedObject(button, @selector(invoke), eventHandlerBlockTouchUpInside, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [button addTarget:eventHandlerBlockTouchUpInside action:@selector(invoke) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        float angle = 270.0 - ((90.0 / 4.0) * button.tag);
        [button setCenter:[[UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMaxX(self.view.bounds), CGRectGetMaxY(self.view.bounds)) radius:CGRectGetMidX(self.view.bounds) startAngle:degreesToRadians(angle) endAngle:degreesToRadians(angle) clockwise:FALSE] currentPoint]];
        return button;
    });
    
    _view = (MTKView *)self.view;
    
    _view.device = MTLCreateSystemDefaultDevice();
    _view.backgroundColor = UIColor.blackColor;
    
    if(!_view.device)
    {
        NSLog(@"Metal is not supported on this device");
        self.view = [[UIView alloc] initWithFrame:self.view.frame];
        return;
    }
    
    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    
    [_renderer mtkView:_view drawableSizeWillChange:_view.bounds.size];
    
    _view.delegate = _renderer;
    
    touch_handler = touch_handler_init_button_arc(self.view);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ (handle_touch = touch_handler(touches.anyObject))(nil); });
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ handle_touch(nil); });
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        handle_touch(^ (unsigned int touch_property) {
            // Converse nonimplication: determines the selection state of the buttons
            
            // state
            for (int i = 0; i < 5; i++) *active_component_bit_vector_ptr ^= 1UL << i;
            NSUInteger label_idx_0 = [self.labels indexOfObjectPassingTest:^BOOL(UILabel * label, NSUInteger tag, BOOL * _Nonnull stop) {
                BOOL objTagged = ([label tag] == 0);
                *stop = objTagged;
                return objTagged;
            }];
            [(UILabel *)[self.labels objectAtIndex:label_idx_0] setText:[NSString stringWithFormat:@"%u%u%u%u%u", ((*active_component_bit_vector_ptr >> 0) & 1U), ((*active_component_bit_vector_ptr >> 1) & 1U), ((*active_component_bit_vector_ptr >> 2) & 1U),  ((*active_component_bit_vector_ptr >> 3) & 1U), ((*active_component_bit_vector_ptr >> 4) & 1U)]];
            
            // sel init
            NSUInteger label_idx_1 = [self.labels indexOfObjectPassingTest:^BOOL(UILabel * label, NSUInteger tag, BOOL * _Nonnull stop) {
                BOOL objTagged = ([label tag] == 1);
                *stop = objTagged;
                return objTagged;
            }];
            [(UILabel *)[self.labels objectAtIndex:label_idx_1] setText:[NSString stringWithFormat:@"%u%u%u%u%u", ((*selected_property_bit_vector_ptr >> 0) & 1U), ((*selected_property_bit_vector_ptr >> 1) & 1U), ((*selected_property_bit_vector_ptr >> 2) & 1U),  ((*selected_property_bit_vector_ptr >> 3) & 1U), ((*selected_property_bit_vector_ptr >> 4) & 1U)]];
            
            // hid init
            *hidden_property_bit_vector_ptr ^= *active_component_bit_vector_ptr; // how is this setting the inverse of the active..?
            NSUInteger label_idx_2 = [self.labels indexOfObjectPassingTest:^BOOL(UILabel * label, NSUInteger tag, BOOL * _Nonnull stop) {
                BOOL objTagged = ([label tag] == 2);
                *stop = objTagged;
                return objTagged;
            }];
            [(UILabel *)[self.labels objectAtIndex:label_idx_2] setText:[NSString stringWithFormat:@"%u%u%u%u%u", ((*hidden_property_bit_vector_ptr >> 0) & 1U), ((*hidden_property_bit_vector_ptr >> 1) & 1U), ((*hidden_property_bit_vector_ptr >> 2) & 1U),  ((*hidden_property_bit_vector_ptr >> 3) & 1U), ((*hidden_property_bit_vector_ptr >> 4) & 1U)]];
            
            // sel end
            // Factor in the current state before setting any property to one
            uint8_t selected_property_bit_mask = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
            selected_property_bit_mask ^= (1UL << touch_property) & ~*active_component_bit_vector_ptr;
            *selected_property_bit_vector_ptr = (*selected_property_bit_vector_ptr | selected_property_bit_mask) & ~*selected_property_bit_vector_ptr;
            NSUInteger label_idx_3 = [self.labels indexOfObjectPassingTest:^BOOL(UILabel * label, NSUInteger tag, BOOL * _Nonnull stop) {
                BOOL objTagged = ([label tag] == 3);
                *stop = objTagged;
                return objTagged;
            }];
            [(UILabel *)[self.labels objectAtIndex:label_idx_3] setText:[NSString stringWithFormat:@"%u%u%u%u%u", ((*selected_property_bit_vector_ptr >> 0) & 1U), ((*selected_property_bit_vector_ptr >> 1) & 1U), ((*selected_property_bit_vector_ptr >> 2) & 1U),  ((*selected_property_bit_vector_ptr >> 3) & 1U), ((*selected_property_bit_vector_ptr >> 4) & 1U)]];
        
            // hid end
            *hidden_property_bit_vector_ptr = selected_property_bit_mask & ~*active_component_bit_vector_ptr;
            for (int i = 0; i < 5; i++) *hidden_property_bit_vector_ptr ^= 1UL << i;
            *hidden_property_bit_vector_ptr ^= *active_component_bit_vector_ptr;
            // factor in the state bit field to get correct hidden bit field for unmasked selected bit field
            NSUInteger label_idx_4 = [self.labels indexOfObjectPassingTest:^BOOL(UILabel * label, NSUInteger tag, BOOL * _Nonnull stop) {
                BOOL objTagged = ([label tag] == 4);
                *stop = objTagged;
                return objTagged;
            }];
            [(UILabel *)[self.labels objectAtIndex:label_idx_4] setText:[NSString stringWithFormat:@"%u%u%u%u%u", ((*hidden_property_bit_vector_ptr >> 0) & 1U), ((*hidden_property_bit_vector_ptr >> 1) & 1U), ((*hidden_property_bit_vector_ptr >> 2) & 1U),  ((*hidden_property_bit_vector_ptr >> 3) & 1U), ((*hidden_property_bit_vector_ptr >> 4) & 1U)]];
            
            // Use the state bit field and the selected bit field to create the hidden bitfield (answers: are they the same?)
//            00000
//            00000 11111
//
//            00100
//            11011 00000
            
            // Exclusive Disjunction (are the two operands different, i.e., not equal?): determines the hidden state of the buttons
            
            /*
             
             0000 state bit mask (not bit field)
             0000 selected
             ———
             00000

             11111 state bit mask (not bit field)
             01000 selected
             ——-
             10111

             */
            
            
            
        });
        touch_handler_init = ((active_component_bit_vector >> 0) & 1U) ? touch_handler_init_button_arc : touch_handler_init_tick_wheel;
        touch_handler = touch_handler_init(self.view);
        (handle_touch = touch_handler(touches.anyObject))(nil);
        handle_touch(nil);
    });
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end
