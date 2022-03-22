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
    Renderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mtkView.backgroundColor = UIColor.blackColor;
    [self.mtkView setDevice:self.mtkView.preferredDevice];
    [self.mtkView setFramebufferOnly:FALSE];
    
    _renderer = [[Renderer alloc] initWithMetalKitView:self.mtkView];
    
    [_renderer mtkView:self.mtkView drawableSizeWillChange:self.mtkView.drawableSize];
    printf("%s\n   ", [NSStringFromCGSize(self.mtkView.drawableSize) UTF8String]);
    printf("%f\n", self.mtkView.layer.contentsScale);
    printf("%f\n", self.mtkView.drawableSize.width / self.mtkView.drawableSize.height);
    printf("%f\n", self.mtkView.drawableSize.height / self.mtkView.drawableSize.width);
    self.mtkView.delegate = _renderer;
    
    [VideoCamera setAVCaptureVideoDataOutputSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)_renderer];
}

@end
