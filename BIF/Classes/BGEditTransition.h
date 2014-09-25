// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"
#import "BGBurstGroupView.h"

@protocol BGEditTransitionListController <NSObject>

- (CGRect)rectForBurstGroupViewForBurstGroup:(BGBurstGroup *)burstGroup;
- (BGBurstGroupView *)stealBurstGroupViewForBurstGroup:(BGBurstGroup *)burstGroup;
- (void)returnBurstGroupView:(BGBurstGroupView *)burstGroupView forBurstGroup:(BGBurstGroup *)burstGroup;

@end

@protocol BGEditTransitionPreviewController <NSObject>

- (CGRect)rectForBurstGroupView;
- (BGBurstGroupView *)stealBurstGroupView;
- (void)setBurstGroupView:(BGBurstGroupView *)burstGroupView;

- (UIView *)mediaView;
- (void)display:(BOOL)display;

@end

@interface BGEditTransition : NSObject<UIViewControllerTransitioningDelegate>

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup
                    fromController:(id<BGEditTransitionListController>)fromController
                      toController:(id<BGEditTransitionPreviewController>)toController;

@end
