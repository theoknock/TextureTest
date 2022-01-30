//
//  ControlView.m
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import "ControlView.h"
#import "Renderer.h"
#include <simd/simd.h>

@import CoreHaptics;

@implementation ControlView {
    UISelectionFeedbackGenerator * haptic_feedback;
    NSDictionary* hapticDict;
}

@synthesize radius, propertyValue;

- (void)setRadius:(CGFloat)radius {
    self->radius = radius;
}

- (CGFloat)radius {
//    [haptic_feedback selectionChanged];
//    [haptic_feedback prepare];
    return (self->radius < CGRectGetMidX(self.frame) ? CGRectGetMidX(self.frame) : self->radius);
}

- (void)setPropertyValue:(CGFloat)propertyValue {
    if (round(propertyValue) != round(self->propertyValue)) {
        [haptic_feedback selectionChanged];
        [haptic_feedback prepare];
        printf("property_value_angle = %f\n", self->propertyValue);
        self->propertyValue = (propertyValue != 0.0) ? propertyValue : self->propertyValue;
    }
    
}

- (CGFloat)propertyValue {
    return self->propertyValue;
}



- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.supportsHaptics = CHHapticEngine.capabilitiesForHardware.supportsHaptics;
    printf("CHHapticEngine %s\n", (self.supportsHaptics) ? "supported" : "not supported");
    __autoreleasing NSError* error = nil;
    _engine = [[CHHapticEngine alloc] initAndReturnError:&error];
    printf("%s\n", (error) ? [error.localizedDescription UTF8String] : "Initialized CHHapticEngine");
    hapticDict =
        @{
         CHHapticPatternKeyPattern:
               @[ // Start of array
                 @{  // Start of first dictionary entry in the array
                     CHHapticPatternKeyEvent: @{ // Start of first item
                             CHHapticPatternKeyEventType:CHHapticEventTypeHapticTransient,
                             CHHapticPatternKeyTime:@0.5,
                             CHHapticPatternKeyEventDuration:@1.0
                             },  // End of first item
                   }, // End of first dictionary entry in the array
                ], // End of array
         }; // End of haptic dictionary

    CHHapticPattern* pattern = [[CHHapticPattern alloc] initWithDictionary:hapticDict error:&error];
    _player = [_engine createPlayerWithPattern:pattern error:&error];
    __weak ControlView * w_control_view = self;
    [_engine setResetHandler:^{
        NSLog(@"Engine RESET!");
        // Try restarting the engine again.
        __autoreleasing NSError* error = nil;
        [w_control_view.engine startAndReturnError:&error];
        if (error) {
            NSLog(@"ERROR: Engine couldn't restart!");
        }
        _player = [_engine createPlayerWithPattern:pattern error:&error];
    }];
    [_engine setStoppedHandler:^(CHHapticEngineStoppedReason reason){
        NSLog(@"Engine STOPPED!");
        switch (reason)
        {
            case CHHapticEngineStoppedReasonAudioSessionInterrupt: {
                NSLog(@"REASON: Audio Session Interrupt");
                // A phone call or notification could have come in, so take note to restart the haptic engine after the call ends. Wait for user-initiated playback.
                break;
            }
            case CHHapticEngineStoppedReasonApplicationSuspended: {
                NSLog(@"REASON: Application Suspended");
                // The user could have backgrounded your app, so take note to restart the haptic engine when the app reenters the foreground. Wait for user-initiated playback.
                break;
            }
            case CHHapticEngineStoppedReasonIdleTimeout: {
                NSLog(@"REASON: Idle Timeout");
                // The system stopped an idle haptic engine to conserve power, so restart it before your app must play the next haptic pattern.
                break;
            }
            case CHHapticEngineStoppedReasonNotifyWhenFinished: {
                printf("CHHapticEngineStoppedReasonNotifyWhenFinished\n");
                break;
            }
            case CHHapticEngineStoppedReasonEngineDestroyed: {
                printf("CHHapticEngineStoppedReasonEngineDestroyed\n");
                break;
            }
            case CHHapticEngineStoppedReasonGameControllerDisconnect: {
                printf("CHHapticEngineStoppedReasonGameControllerDisconnect\n");
                break;
            }
            case CHHapticEngineStoppedReasonSystemError: {
                NSLog(@"REASON: System Error");
                // The system faulted, so either continue without haptics or terminate the app.
                break;
            }
        }
    }];

    [_engine startWithCompletionHandler:^(NSError* returnedError) {
        if (returnedError)
            NSLog(@"--- Error starting haptic engine: %@", returnedError.debugDescription);
    }];
        
    [_player startAtTime:CHHapticTimeImmediate error:&error];
    
    [_engine stopWithCompletionHandler:^(NSError* _Nullable error) {
        if (error)
            NSLog(@"--- Error stopping haptic engine: %@", error.debugDescription);
    }];
    

    haptic_feedback = [[UISelectionFeedbackGenerator alloc] init];
    [haptic_feedback prepare];
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
