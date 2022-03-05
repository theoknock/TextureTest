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
