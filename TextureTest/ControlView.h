//
//  ControlView.h
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@import CoreHaptics;
@import QuartzCore;
@import CoreGraphics;

NS_ASSUME_NONNULL_BEGIN

@interface ControlLayer : CAGradientLayer

@end

NS_ASSUME_NONNULL_END

NS_ASSUME_NONNULL_BEGIN



@interface ControlView : UIView

@property (strong, nonatomic) IBOutlet UILabel *stateBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *highlightedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *selectedBitVectorLabel;
@property (strong, nonatomic) IBOutlet UILabel *hiddenBitVectorLabel;

@end

NS_ASSUME_NONNULL_END
