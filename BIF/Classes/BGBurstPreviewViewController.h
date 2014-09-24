// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"

@class BGBurstPreviewViewController;
@protocol BGBurstPreviewViewControllerDelegate <NSObject>

- (void)burstPreviewViewControllerWantsDismissal:(BGBurstPreviewViewController *)controller;

@end

@interface BGBurstPreviewViewController : UIViewController

@property (nonatomic, strong, readonly) UIView *mediaView;
@property (nonatomic, assign, readonly) CGRect normalFrameForMediaView;

@property (nonatomic, weak) id<BGBurstPreviewViewControllerDelegate> delegate;

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup NS_DESIGNATED_INITIALIZER;

- (void)display:(BOOL)display;

@end
