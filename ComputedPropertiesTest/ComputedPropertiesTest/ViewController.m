//
//  ViewController.m
//  ComputedPropertiesTest
//
//  Created by Xcode Developer on 1/25/22.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
    const float * button_angles_ptr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __block int i = 0;
    float(^(^get_i)(void))(void);
    get_i = ^ float (void) {
        i++;
        return get_i()();
    }();
    const float button_angles[] =
    {1.0, 1.0, 1.0, 1.0, 1.0, get_i()};
    for (int k = 0; k < 10; k++) printf("%f\n", button_angles[5]);
}

@end
