//
//  transition_block.c
//  TextureTest
//
//  Created by Xcode Developer on 3/4/22.
//

#include "transition_block.h"


// long ... (void) = wrapper for long(^)(long(^)(void))
static long (^(^blk)(void))(long (^(^__strong)(long (^__strong)(void)))(void));


// touch handler is passed as a block literal
// handle_touch_init returns the passed block literal as its return value
// the return value is assigned to handle_touch
// handle_touch executes the passed block literal returned by handle_touch_init
static long (^(^handle_touch_init)(long (^__strong touch_handler)(void)))(void);
static long (^handle_touch)(void);

void touch_blocks(void) {
    ^ long (long(^t_block)(void)) {
        return t_block(); 
    }(^ (long (^handle_touch)(void)) {
        return handle_touch;
    }(^ (long(^(^touch_handler)(void))(void)) {
        return ^ (long(^touch_handler_init)(void)) {
            return touch_handler_init;
        }(touch_handler());
    }(^{
        return ^ long {
            return (long)1;
        };
    })));
    
    
    ^ (long (^handle_touch)(void)) {
        return handle_touch;
    }(^ (long(^(^touch_handler)(void))(void)) {
        return ^ (long(^touch_handler_init)(void)) {
            return touch_handler_init;
        }(touch_handler());
    }(^{
        return ^ long {
            return (long)1;
        };
    }));
    
    
    /*
    long(^blk_init)(void) = ^ (long(^(^t_h)(void))(void)) {
        return ^ (long(^h_t)(void)) {
            return h_t;
        }(t_h());
    }(^{
        return ^ long {
            return (long)1;
        };
    });
     */
}


/*
 long(^perform_post_transition)(void) = ^ long {
     return (long)1;
 };
 long (^(^post_transition)(void))(void) = ^{
     return ^ long {
         return (long)1;
     };
 };

 long(^handle_post_transition_touch)(void) = ^ long {
     return (long)1;
 };
 long (^(^post_transition_touch_handler)(void))(void) = ^{
     return ^ long {
         return (long)1;
     };
 };

 long (^ASDF)(long(^)(void)) = ^ long (void) {
     return ^ long {
         return (long)1;
     };
 };

 long (^(^param)(long(^)(void)))(void) = ^ (long(^blk_param_1)(void)) {
     return ^ long {
         return (long)1;
     };
 };



 long (^(^blk_a_1)(long(^)(void)))(void) = ^ (long(^blk_param_1)(void)) {
     return ^ (long (^blk_param_a)(long(^)(void))) {
         return blk_param_a(blk_param_1);
 //        return ^ long {
 //            return (long)1;
 //        };
     };
 };


 //long (^(^blk_c)(long(^)(void)))(void) = ^{
 //    return ^ long {
 //        return ^ (void(^l_b)(long)) {
 //            return ^ (long l_a) {
 //
 //            };
 //        };
 //    };
 //};



 void (^(^(^(^(^(^l)(void (^__strong)(long)))(void(^)(long)))(void (^__strong)(long)))(long))(void (^__strong)(long)))(long);



 long (^(^(^post_transition)(long (^(^__strong)(void))(void)))(long (^(^__strong)(long (^__strong)(void)))(void)))(void) = ^ (long(^(^post_transition_touch_handler)(void))(void)) {
     return ^ (long(^(^post_transition_animation)(long(^)(void)))(void)) {
         return post_transition_animation(post_transition_touch_handler());
     };
 };

 void (^test)(void) = ^{
     long (^perform_post_transition)(void) = (post_transition(blk_a))(blk_1);
     long (^perform_post_transition_block_literals)(void) = (post_transition(^{
         return ^ long {
             return (long)1;
         };
     }))(^ (long(^blk_param_1)(void)) {
         return ^ long {
             return (long)1;
         };
     });
 };
 
 */

/*
 // state_setter goes here

 // block literal for post-transition blocks

 long(^(^post_transition_init)(long(^)(void)))(void) = ^ (long(^b)(long(^b)(void))) {
     return ^{
         return (long)1;
     };
 };




 ^ (long(^b)(void)) {
     return b;
 }(^{
     return(long)('b');
 });



 long (^ _Nonnull post_handle_touch)(void);
 long (^(^ _Nonnull transition)(CGPoint, CGFloat))(long (^ _Nonnull)(void));
 long (^state)(long (^(^ _Nonnull)(CGPoint, CGFloat))(long (^ _Nonnull)(void)));
 state = ^ long (long (^(^ _Nonnull __strong animate_transition)(CGPoint, CGFloat))(long (^ _Nonnull __strong)(void))) {
     return (animate_transition(center_point, radius))(post_handle_touch);
 };
 */
