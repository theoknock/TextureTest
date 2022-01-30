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
#import "ControlView.h"

@interface GameViewController : UIViewController

@property (strong, nonatomic) IBOutlet ControlView *controlView;

@end
