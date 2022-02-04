//
//  TransitionAnimation.m
//  TextureTest
//
//  Created by Xcode Developer on 2/3/22.
//

#import "TransitionAnimation.h"

// To-Do: the create-display-link block should return a destroy-display-link block

@implementation TransitionAnimation {
//    TransitionAnimationBlock transition_animation_block;
}

- (instancetype)init {
    if (self == [super init]) {
        void(^blah(void(^)(void)))(void);
        blah(^{ printf("blah\n"); });
//        typedef void (^display_link_invalidate)(CADisplayLink *);
//        typedef void (^(^display_link_init(display_link_invalidate(^)(CADisplayLink * )))(void))(void);
//        void(^transition_animation(void))(void(^(^animate_transition)(CADisplayLink *))(CADisplayLink *)); // Create and destroy CADisplayLink
//
//        transition_animation(^(CADisplayLink * display_link) {
//            return ^{
//            return ^(CADisplayLink * display_link) {
//
//            };
//            };
//        });
    }
    
    return self;
}







//    CADisplayLink * dl = blk(^ CADisplayLink * {
//    static CADisplayLink * display_link;
//    [display_link invalidate];
//    display_link = [CADisplayLink displayLinkWithTarget:^{} selector:@selector(invoke)];
//    display_link.preferredFramesPerSecond = 1.0;
//    [display_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//    return display_link;
//});
//
//__block CADisplayLink * display_link;
//static void (^animation_completion_block)(CADisplayLink *)  = ^ (CADisplayLink * display_link) {
//    [display_link invalidate];
//    [display_link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//};
//typedef void(^block_type(void(^)(CADisplayLink * )))(void);
//void(^block(void(^)(CADisplayLink * )))(void);
////    block()
//block(^(CADisplayLink * display_link) {
//
//});
//typedef void (^animation_block_type)(CADisplayLink *)
//animation_block_type (^animation(animation_block_type(^(^)(block_type))(CADisplayLink * )))(void);
////
//animation(^void (^)(CADisplayLink *)(void)));
//
//animation(^ (CADisplayLink * display_link) {
//    [display_link invalidate];
//    display_link = [CADisplayLink displayLinkWithTarget:^{} selector:@selector(invoke)];=
//    (display_link).preferredFramesPerSecond = 1.0;
//    [display_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//
//    return ^ (void(^animation_block)(CADisplayLink *)) {
//
//    };
//});

//
//    transition_animation = ^{
//        float frameInterval = .05;
//        void (^(^animation_transition)(void(^)(CADisplayLink *)))(void) = ^ (void(^eventHandlerCompletionBlock)(CADisplayLink *)) {
//            return ^{
//                [display_link invalidate];
//                display_link = [CADisplayLink displayLinkWithTarget:eventHandlerBlock selector:@selector(invoke)];
//                display_link.preferredFramesPerSecond = frameInterval;
//
//                [display_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//            };
//        }(^ (CADisplayLink * display_link) {
//            [display_link invalidate];
//            [display_link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//        });
//
//    };

@end
