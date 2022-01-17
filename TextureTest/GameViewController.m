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

#define MASK_NONE           0b0000
#define MASK_ALL            0b1111

static unsigned int state_bit_field       = MASK_ALL;
static unsigned int selected_bit_field    = MASK_NONE;
static unsigned int highlighted_bit_field = MASK_NONE;
static unsigned int hidden_bit_field      = MASK_NONE;

static unsigned int * bit_fields[3] =
{
    &state_bit_field, &selected_bit_field, &highlighted_bit_field, &hidden_bit_field
};

static const unsigned int bits[5] =
{
    0b00001, 0b00010, 0b00100, 0b01000, 0b10000
};

//bool nth_is_set = (v & (1 << n)) != 0;
//bool nth_is_set = (v >> n) & 1;

static unsigned int (^button_state)(unsigned int *, unsigned int) = ^ unsigned int (unsigned int *bit_field, unsigned int bit) {
    *bit_field = (*bit_field & 0) | bits[bit];
//    hidden_bit_field   =  state_bit_field;  // becomes what state is now (always the opposite of state)
//    selected_bit_field = // set selected_bit_field to zero if zero; otherwise, keep 0
//    state_bit_field    = ~state_bit_field;  // inverts state: 11111 = nothing selected, nothing hidden; 00000 = one selected, one shown (bit)
//    hidden_bit_field   =  state_bit_field | bits[bit];      //
//    selected_bit_field = ~state_bit_field  & selected_bit_field;
//
//    selected_bit_field |= bits[bit] & (state_bit_field & MASK_ALL);
    
    return *bit_field & bit;
};

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
                    [button_collection[index] setSelected:(selected_bit_field >> index) & 1];
                    [button_collection[index] setHighlighted:(highlighted_bit_field >> index) & 1];
//                    [button_collection[index] setHidden:(hidden_bit_field >> index) & 1];
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
    return (new_max - new_min) * (old_value - old_min) / (old_max - old_min) + new_min;
};

//static void (^reduce)(void) = ^{
//    state();
//    filter(buttons)(^ (UIButton * _Nonnull button, unsigned int property) {
//        printf("\n%lu\tstate\t%s\t\t", button.tag, (state_bits & (1 << property)) ? "TRUE" : "FALSE");
//        printf("%lu\tselected\t%s\t\t", button.tag, (selected_bits & (1 << property)) ? "TRUE" : "FALSE");
//        printf("%lu\tenabled\t%s\n", button.tag, (enabled_bits & (1 << property)) ? "TRUE" : "FALSE");
//        [button setSelected:(selected_bits & (1 << property)) ? TRUE : FALSE];
////        [button setHidden:(enabled_bits & (1 << property)) ? FALSE : TRUE];
//    });
//};

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
            button_state((UITouchPhaseEnded ^ touch.phase) ? &highlighted_bit_field : &selected_bit_field, touch_property);
            filter(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [button setHighlighted:(UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                [button setCenter:^{
                    float angle  = rescale(button.tag, 0.0, 4.0, 180.0, 270.0);
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
