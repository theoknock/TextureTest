//
//  ControlView.m
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import "ControlView.h"
#import "Renderer.h"
#include <simd/simd.h>

@implementation ControlView {
    UISelectionFeedbackGenerator * haptic_feedback;
}

@synthesize radius, propertyValue;

- (void)setRadius:(CGFloat)radius {
    self->radius = radius;
}

- (CGFloat)radius {
    return (self->radius < CGRectGetMidX(self.frame) ? CGRectGetMidX(self.frame) : self->radius);
}

- (void)setPropertyValue:(CGFloat)propertyValue {
    printf("property_value_angle = %f\n", self->propertyValue);
    self->propertyValue = (propertyValue != 0.0) ? propertyValue : self->propertyValue;
}

- (CGFloat)propertyValue {
    return self->propertyValue;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    haptic_feedback = [[UISelectionFeedbackGenerator alloc] init];
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
    [haptic_feedback prepare];
    [haptic_feedback selectionChanged];
    [haptic_feedback prepare];
}

@end
