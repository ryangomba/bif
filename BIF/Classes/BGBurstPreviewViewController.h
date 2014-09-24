// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"

@class BGBurstPreviewViewController;
@protocol BGBurstPreviewViewControllerDelegate <NSObject>

- (void)burstPreviewViewControllerWantsDismissal:(BGBurstPreviewViewController *)controller;

@end

@interface BGBurstPreviewViewController : UIViewController

@property (nonatomic, weak) id<BGBurstPreviewViewControllerDelegate> delegate;

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup NS_DESIGNATED_INITIALIZER;

@end
