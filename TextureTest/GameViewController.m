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

static void (^(^filter)(__strong UIButton * _Nonnull [_Nonnull 5]))(void (^__strong)(UIButton * _Nonnull, unsigned int)) = ^ (__strong UIButton * _Nonnull button_collection[5]) {
    dispatch_queue_t enumerator_queue  = dispatch_queue_create("enumerator_queue", DISPATCH_QUEUE_SERIAL);
    return ^ (void(^enumeration)(UIButton * _Nonnull, unsigned int)) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            dispatch_apply(5, enumerator_queue, ^(size_t index) {
                dispatch_barrier_async(dispatch_get_main_queue(), ^{
                    enumeration(button_collection[index], (unsigned int)index); // no return value
                });
            });
        });
    };
};

//static void (^(^(^reduce)(UIButton * _Nonnull __strong *))(UIButton *(^__strong)(UIButton *__strong, unsigned int)))(UIButton *(^__strong)(UIButton * _Nonnull __strong, unsigned int)) =
//^ (__strong UIButton * _Nonnull button_collection[5]) {
//    dispatch_queue_t enumerator_queue  = dispatch_queue_create("enumerator_queue", DISPATCH_QUEUE_SERIAL);
//    return ^ (void *(^reduction)(UIButton *, unsigned int)) {
//        return ^ (UIButton * (^reductor)(UIButton * _Nonnull, unsigned int)) {
//            dispatch_barrier_async(dispatch_get_main_queue(), ^{
//                dispatch_apply(5, enumerator_queue, ^(size_t index) {
//                    dispatch_barrier_async(dispatch_get_main_queue(), ^{
//                        reduction(reductor(button_collection[index], (unsigned int)index), (unsigned int)index);
//                    });
//                });
//            });
//        };
//    };
//};
//
//= ^ (__strong UIButton * _Nonnull button_collection[5]) {
//    return ^ (void(^b)(UIButton * _Nonnull)) {
//        return ^ (UIButton *(^c)(unsigned int)) {
//        };
//    };
//};

static float (^rescale)(float old_value, float old_min, float old_max, float new_min, float new_max) = ^(float old_value, float old_min, float old_max, float new_min, float new_max) {
    return (new_max - new_min) * /*(fmax(old_min, fmin(old_value, old_max))*/ (old_value - old_min) / (old_max - old_min) + new_min;
};

char state_bits    = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
char selected_bits = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
char enabled_bits  = (1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4);

const int torch_level_bit       = (1 << 0);
const int lens_position_bit     = (1 << 1);
const int exposure_duration_bit = (1 << 2);
const int iso_bit               = (1 << 3);
const int zoom_factor_bit       = (1 << 4);

/*
 state_bits = ~state_bits;
 enabled_bits = state_bits | selected_bits;
 selected_bits = ~state_bits & selected_bits;
 enabled_bits = enabled_bits | selected_bits;
 */

static void (^reduce)(void) = ^{
    state_bits = ~state_bits;
    enabled_bits = state_bits | selected_bits;
    selected_bits = ~state_bits & selected_bits;
    enabled_bits = enabled_bits | selected_bits;
    filter(buttons)(^ (UIButton * _Nonnull button, unsigned int property) {
        printf("\n%lu\tstate\t%s\t\t", button.tag, (state_bits & (1 << property)) ? "TRUE" : "FALSE");
        printf("%lu\tselected\t%s\t\t", button.tag, (selected_bits & (1 << property)) ? "TRUE" : "FALSE");
        printf("%lu\tenabled\t%s\n", button.tag, (enabled_bits & (1 << property)) ? "TRUE" : "FALSE");
        [button setSelected:(selected_bits & (1 << property)) ? TRUE : FALSE];
//        [button setHidden:(enabled_bits & (1 << property)) ? FALSE : TRUE];
    });
};

static void (^(^(^touch_handler_init)(UIView *))(UITouch *))(void) = ^ (UIView * view) {
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
        static unsigned int touch_property;
        return ^{
            touch_point = [touch preciseLocationInView:view];
            touch_angle = atan2(touch_point.y - maxY, touch_point.x - maxX) * (180.0 / M_PI);
            if (touch_angle < 0.0) touch_angle += 360.0;
            touch_property = (unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0));
            filter(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [button setSelected:!(UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                [button setHighlighted:(UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                [button setCenter:^{
                    float angle  = rescale(button.tag, 0, 4, 180.0, 270.0);
                    float radians = degreesToRadians(angle);
                    float radius = sqrt(pow(touch_point.x - maxX, 2.0) +
                                        pow(touch_point.y - maxY, 2.0));
                    radius = fmaxf(midX, fminf(radius, maxX));
                    CGFloat x = maxX - radius * -cos(radians);
                    CGFloat y = maxY - radius * -sin(radians);
                    return CGPointMake(x, y);
                }()];
            });
        };
        
    };
};
static void (^(^touch_handler)(UITouch *))(void);
static void (^handle_touch)(void);


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
        [button setImage:[UIImage systemImageNamed:@"questionmark.circle" withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:42] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationPreferringMulticolor]]] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:42] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationPreferringMulticolor]]] forState:UIControlStateHighlighted];
        [button setImage:[UIImage systemImageNamed:@"exclamationmark.circle.fill" withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:42] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationPreferringMulticolor]]] forState:UIControlStateSelected];
        [button sizeToFit];
        [button setUserInteractionEnabled:FALSE];
        void (^eventHandlerBlockTouchUpInside)(void) = ^{
//            selected_bits = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
//            selected_bits |= (1 << button.tag);
//            printf("\n%lu\t\t\tstate\t%s\t\t", button.tag, (state_bits & (1 << button.tag)) ? "TRUE" : "FALSE");
//            printf("%lu\t\t\tselected\t%s\t\t", button.tag, (selected_bits & (1 << button.tag)) ? "TRUE" : "FALSE");
//            printf("%lu\t\t\tenabled\t%s\n", button.tag, (enabled_bits & (1 << button.tag)) ? "TRUE" : "FALSE");
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
    
    touch_handler = touch_handler_init(self.view);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ (handle_touch = touch_handler(touches.anyObject))(); });
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ handle_touch(); });
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ handle_touch(); });
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end
