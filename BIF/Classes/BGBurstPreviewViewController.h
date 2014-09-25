// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"
#import "BGBurstGroupView.h"

// HACK messy
#import "BGEditTransition.h"

@class BGBurstPreviewViewController;
@protocol BGBurstPreviewViewControllerDelegate <NSObject>

- (void)burstPreviewViewControllerWantsDismissal:(BGBurstPreviewViewController *)controller;

@end

@interface BGBurstPreviewViewController : UIViewController<BGEditTransitionPreviewController>

@property (nonatomic, weak) id<BGBurstPreviewViewControllerDelegate> delegate;

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup NS_DESIGNATED_INITIALIZER;

@end
