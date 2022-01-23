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

int decimalFromBinary(long long n);
long long binaryFromDecimal(int n);

//int main() {
//    int dec = 0;
//    long long bin = 0;
//
//    printf("Enter a binary number: ");
//    scanf("%lld", &bin);
//    dec = decimalFromBinary(bin);
//    printf("%lld in binary = %d in decimal", bin, dec);
//
//    printf("Enter a decimal number: ");
//    scanf("%d", &dec);
//    bin = binaryFromDecimal(dec);
//    printf("%d in decimal = %lld to binary", dec, bin);
//
//    return 0;
//}

int decimalFromBinary(long long n) {
    int decimalNumber = 0, i = 0, remainder;
    while (n!=0)    {
        remainder = n%10;
        n /= 10;
        decimalNumber += remainder*pow(2,i);
        ++i;
    }
    return decimalNumber;
}

long long binaryFromDecimal(int n){
    long long binaryNumber = 0;
    int remainder, i=1;
    
    while(n != 0) {
        remainder = n%2;
        n = n / 2;
        binaryNumber += remainder * i;
        i = i * 10;
    }
    
    return binaryNumber;
}


#define MASK_NONE           0b00000
#define MASK_ALL            0b11111

static long long state_bit_field       = MASK_ALL;
static long long selected_bit_field    = MASK_NONE;
static long long highlighted_bit_field = MASK_NONE;
static long long hidden_bit_field      = MASK_NONE;

static long long * bit_fields[4] =
{
    &state_bit_field, &selected_bit_field, &highlighted_bit_field, &hidden_bit_field
};

static const long long bits[5] =
{
    0b00001, 0b00010, 0b00100, 0b01000, 0b10000
};

static long long (^button_state)(long long *, long long) = ^ long long (long long *bit_field, long long bit) {
    //    printf("%lld to binary\n", binaryFromDecimal(state_bit_field));
    // flip the state here
    state_bit_field = ~state_bit_field;
    // flip the selected button here
    *bit_field = (*bit_field & MASK_NONE);// | (state_bit_field | bits[bit]);
    hidden_bit_field   =  state_bit_field;  // becomes what state is now (always the opposite of state)
    selected_bit_field = // set selected_bit_field to zero if zero; otherwise, keep 0
    state_bit_field    = ~state_bit_field;  // inverts state: 11111 = nothing selected, nothing hidden; 00000 = one selected, one shown (bit)
    hidden_bit_field   =  state_bit_field | bits[bit];      //
    selected_bit_field = ~state_bit_field  & selected_bit_field;
    
    selected_bit_field |= bits[bit] & (state_bit_field & MASK_ALL);
    
    return *bit_field & bit;
};

uint8_t mask[8] = {1 << 0, 1 << 1, 1 << 2, 1 << 3, 1 << 4, 1 << 5};

int getByte(int x, int n) {
    return (x >> (n<<5)) & 0xff;
}

static void (^print_byte)(long long, long long) = ^ (long long bit_field, long long bit) {
    printf("\n\t%d\n", ((BOOL)(getByte(bit_field, bit) & mask[bit]) ? 1 : 0));
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
                    //                    [button_collection[index] setSelected:(selected_bit_field >> index) & 1];
                    //                    [button_collection[index] setHighlighted:(highlighted_bit_field >> index) & 1];
                    //                    [button_collection[index] setHidden:(hidden_bit_field >> index) & 1];
                    enumeration(button_collection[index], (unsigned int)index); // no return value
                });
            });
        });
    };
};

static float (^rescale)(float old_value, float old_min, float old_max, float new_min, float new_max) = ^(float old_value, float old_min, float old_max, float new_min, float new_max) {
    return (new_max - new_min) * (old_value - old_min) / (old_max - old_min) + new_min;
};

static  uint8_t         active_component_bit_vector     = (1 << 0);
static  uint8_t * const active_component_bit_vector_ptr = &active_component_bit_vector;
static  uint8_t         selected_property_bit_vector     = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
static  uint8_t * const selected_property_bit_vector_ptr = &selected_property_bit_vector;
static  uint8_t         hidden_property_bit_vector     = (0 << 0 | 0 << 1 | 0 << 2 | 0 << 3 | 0 << 4);
static  uint8_t * const hidden_property_bit_vector_ptr = &hidden_property_bit_vector;

static void (^(^(^touch_handler_init)(UIView *))(UITouch *))(void(^)(unsigned int)) = ^ (UIView * view) {
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
    
    static int exec_count;
    
    return ^ (UITouch * touch) {
        static CGPoint touch_point;
        static CGFloat touch_angle;
        static unsigned int touch_property;
        static UITouchPhase touch_phase;
        return ^ (void(^ _Nullable set_button_state)(unsigned int)) {
            touch_point = [touch preciseLocationInView:view];
            touch_angle = (atan2(touch_point.y - maxY, touch_point.x - maxX) * (180.0 / M_PI)) + 360.0;
            touch_property = (unsigned int)round(rescale(touch_angle, 180.0, 270.0, 0.0, 4.0));
            touch_phase = touch.phase;
            if (set_button_state != nil) set_button_state(touch_property);
            filter(buttons)(^ (UIButton * _Nonnull button, unsigned int index) {
                [button setSelected:(BOOL)(getByte(selected_property_bit_vector, index) & mask[index])];
                //                [button setHidden:!(UITouchPhaseEnded ^ touch.phase) & (hidden_property_bit_vector | index) & !(touch_property ^ button.tag)];
                [button setHighlighted:(UITouchPhaseEnded ^ touch.phase) & !(touch_property ^ button.tag)];
                [button setCenter:^{
                    float angle  = rescale(button.tag, 0.0, 4.0, 180.0, 270.0); // float angle  = (((selected_property_bit_vector >> index) & 1) & (UITouchPhaseEnded ^ touch.phase)) ? rescale(index, 0.0, 4.0, 180.0, 270.0) : touch_angle;
                    float radians = degreesToRadians(angle);
                    float radius = sqrt(pow(touch_point.x - maxX, 2.0) +
                                        pow(touch_point.y - maxY, 2.0));
                    radius = fmaxf(midX, fminf(radius, maxX));
                    CGFloat x = maxX - radius * -cos(radians);
                    CGFloat y = maxY - radius * -sin(radians);
                    return CGPointMake(x, y);
                }()];
                {
                    [button setTitle:[NSString stringWithFormat:@"%d - %d",
                                      (BOOL)(getByte(selected_property_bit_vector, index) & mask[index]),
                                      (BOOL)(getByte(hidden_property_bit_vector, index) & mask[index])] forState:UIControlStateNormal];
                    [button sizeToFit];
                    [[button titleLabel] setAdjustsFontSizeToFitWidth:CGRectGetWidth([[button titleLabel] frame])];
                };
            });
        };
        
    };
};

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
        [button setImage:[UIImage systemImageNamed:@"questionmark.circle" withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:42] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationPreferringMulticolor]]] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:42] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationPreferringMulticolor]]] forState:UIControlStateHighlighted];
        [button setImage:[UIImage systemImageNamed:@"exclamationmark.circle.fill" withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:42] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationPreferringMulticolor]]] forState:UIControlStateSelected];
        
        [button setTitle:[NSString stringWithFormat:@"%d - %d",
                          (BOOL)(getByte(selected_property_bit_vector, index) & mask[index]),
                          (BOOL)(getByte(hidden_property_bit_vector, index) & mask[index])] forState:UIControlStateNormal];
        [button sizeToFit];
        [[button titleLabel] setAdjustsFontSizeToFitWidth:CGRectGetWidth([[button titleLabel] frame])];
        
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
    
    touch_handler = touch_handler_init(self.view);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ (handle_touch = touch_handler(touches.anyObject))(nil); });
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{ handle_touch(nil); });
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    static int exec_count;
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        handle_touch(^ (unsigned int touch_property) {
            *active_component_bit_vector_ptr ^= 1UL << 0;
            printf("%d\t\t%u\n", exec_count++, (*active_component_bit_vector_ptr >> 0) & 1U);
            *selected_property_bit_vector_ptr &= ~(*selected_property_bit_vector_ptr);                                                                       // invert selection/hidden mask
            *selected_property_bit_vector_ptr |= mask[touch_property];                                                                                        // set the selected bit
            *hidden_property_bit_vector_ptr ^= ~((*selected_property_bit_vector_ptr & getByte(*selected_property_bit_vector_ptr, mask[touch_property]))); // unmask all hidden except the selected bit });
        });
    });
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end
