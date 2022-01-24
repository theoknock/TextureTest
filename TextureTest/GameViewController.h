//
//  GameViewController.h
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "Renderer.h"

// Our iOS view controller
@interface GameViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *labelStackView;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray * labels;

@end
