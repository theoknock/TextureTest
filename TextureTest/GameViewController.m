//
//  GameViewController.m
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#import "GameViewController.h"
#import "Renderer.h"


@implementation GameViewController
{
    MTKView *_view;
    Renderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _view = (MTKView *)self.view;
    [_view.layer setAffineTransform:CGAffineTransformMakeRotation(0)];
    [_view.layer setAffineTransform:CGAffineTransformScale(_view.layer.affineTransform, -1, -1)];
    _view.device = MTLCreateSystemDefaultDevice();
    _view.backgroundColor = UIColor.blackColor;
    
    if(!_view.device)
    {
        NSLog(@"Metal is not supported on this device");
        self.view = [[UIView alloc] initWithFrame:self.view.frame];
        return;
    }
    
    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    printf("%s\n   ", [NSStringFromCGSize(_view.drawableSize) UTF8String]);
    
    _view.delegate = _renderer;
    [VideoCamera setAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)_renderer];
}

@end
