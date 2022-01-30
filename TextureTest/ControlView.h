//
//  ControlView.h
//  TextureTest
//
//  Created by Xcode Developer on 1/29/22.
//

#import <UIKit/UIKit.h>
@import CoreHaptics;

NS_ASSUME_NONNULL_BEGIN

@interface ControlView : UIView

@property (nonatomic, setter = setRadius:, getter = radius) CGFloat radius;
@property (nonatomic, setter = setPropertyValue:, getter = propertyValue) CGFloat propertyValue;
@property (nonatomic, assign) BOOL supportsHaptics;
@property (nonatomic, strong) CHHapticEngine* engine;
@property (nonatomic, strong) id<CHHapticPatternPlayer> player;

@end

NS_ASSUME_NONNULL_END
