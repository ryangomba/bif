// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGEditTransition.h"

#import <RGFoundation/RGGeometry.h>

#import "BIFHelpers.h"

#define kVCMinScale 1.0

@interface BGEditTransition ()<UIViewControllerAnimatedTransitioning>

@property (nonatomic, strong) BGBurstGroup *burstGroup;

@property (nonatomic, strong) UIView *topSnapshotView;
@property (nonatomic, strong) UIView *bottomSnapshotView;

@property (nonatomic, assign) BOOL isPresenting;

@end


@implementation BGEditTransition

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup
                    fromController:(id<BGEditTransitionListController>)fromController
                      toController:(id<BGEditTransitionPreviewController>)toController {
    
    if (self = [super init]) {
        self.burstGroup = burstGroup;
    }
    return self;
}


#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {

    [self setIsPresenting:YES];
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {

    [self setIsPresenting:NO];
    return self;
}


#pragma mark -
#pragma mark UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return [self animationDuration];
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if (self.isPresenting) {
        [self animatePresentTransition:transitionContext];
    } else {
        [self animateDismissTransition:transitionContext];
    }
}


#pragma mark -
#pragma mark Private

- (CGFloat)animationDuration {
    return 1.0;
}

- (void)animatePresentTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController<BGEditTransitionListController> *fromVC = (id)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController<BGEditTransitionPreviewController> *toVC = (id)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    containerView.backgroundColor = kBGBackgroundColor;
    
    CGRect originatingBurstViewRect = [fromVC rectForRangePickerViewForBurstGroup:self.burstGroup];

    CGRect topSnapshotRect = CGRectMake(0.0, 0.0, fromVC.view.bounds.size.width, originatingBurstViewRect.origin.y);
    UIView *topSnapshotView = [fromVC.view resizableSnapshotViewFromRect:topSnapshotRect afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    topSnapshotView.frame = topSnapshotRect;
    self.topSnapshotView = topSnapshotView;
    
    CGRect bottomSnapshotRect = CGRectMake(0.0, CGRectGetMaxY(originatingBurstViewRect), fromVC.view.bounds.size.width, fromVC.view.bounds.size.height - CGRectGetMaxY(originatingBurstViewRect));
    UIView *bottomSnapshotView = [fromVC.view resizableSnapshotViewFromRect:bottomSnapshotRect afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    bottomSnapshotView.frame = bottomSnapshotRect;
    self.bottomSnapshotView = bottomSnapshotView;
    
    [containerView addSubview:topSnapshotView];
    [containerView addSubview:bottomSnapshotView];
    
    [fromVC.view removeFromSuperview];
    
    CGRect toVCRect = toVC.view.frame;
    toVCRect.origin.y = originatingBurstViewRect.origin.y - 500.0;
    toVC.view.frame = toVCRect;

    [containerView addSubview:toVC.view];
    [toVC display:NO];
    
    BGBurstGroupRangePicker *rangePickerView = [fromVC stealRangePickerViewForBurstGroup:self.burstGroup];
    [rangePickerView setEditable:YES animated:YES];
    rangePickerView.frame = [fromVC rectForRangePickerViewForBurstGroup:self.burstGroup];
    [containerView addSubview:rangePickerView];
    
    toVC.view.backgroundColor = [UIColor clearColor];
    [toVC prepareRangePickerView:rangePickerView];
    
    UIView *mediaView = [toVC mediaView];
    
    mediaView.alpha = 0.0;
    mediaView.transform = CGAffineTransformMakeScale(0.5, 0.5);

    CGFloat duration = [self animationDuration] * [transitionContext isAnimated];

    [UIView animateWithDuration:duration - 0.15 delay:0.15 usingSpringWithDamping:0.85 initialSpringVelocity:0.0 options:0 animations:^{
        mediaView.alpha = 1.0;
        mediaView.transform = CGAffineTransformIdentity;
    } completion:nil];

    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.85 initialSpringVelocity:0.0 options:0 animations:^{
        toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
        
        [fromVC.view setTransform:CGAffineTransformMakeScale(kVCMinScale, kVCMinScale)];

        CGRect topSnapshotFrame = topSnapshotView.frame;
        topSnapshotFrame.origin.y = -topSnapshotView.bounds.size.height;
        topSnapshotView.frame = topSnapshotFrame;
        topSnapshotView.alpha = 0.0;
        
        rangePickerView.frame = [toVC rectForRangePickerView];
        
        CGRect bottomSnapshotFrame = bottomSnapshotView.frame;
        bottomSnapshotFrame.origin.y = containerView.bounds.size.height;
        bottomSnapshotView.frame = bottomSnapshotFrame;
        bottomSnapshotView.alpha = 0.0;

        [toVC display:YES];

    } completion:^(BOOL finished) {
        [fromVC.view setTransform:CGAffineTransformIdentity];

        toVC.view.backgroundColor = kBGBackgroundColor;
        
        [toVC placeRangePickerView:rangePickerView];
        
        [transitionContext completeTransition:YES];
    }];
}

- (void)animateDismissTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController<BGEditTransitionPreviewController> *fromVC = (id)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController<BGEditTransitionListController> *toVC = (id)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];

    [toVC.view setTransform:CGAffineTransformMakeScale(kVCMinScale, kVCMinScale)];

    CGFloat duration = [self animationDuration] * [transitionContext isAnimated];

    fromVC.view.backgroundColor = [UIColor clearColor];
    
    CGRect originatingBurstViewRect = [toVC rectForRangePickerViewForBurstGroup:self.burstGroup];
    
    BGBurstGroupRangePicker *rangePickerView = [fromVC stealRangePickerView];
    [rangePickerView setEditable:NO animated:YES];
    rangePickerView.frame = [fromVC rectForRangePickerView];
    [containerView addSubview:rangePickerView];
    
    [UIView animateWithDuration:duration / 2 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:0 animations:^{
        fromVC.mediaView.alpha = 0.0;
        fromVC.mediaView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:nil];
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.85 initialSpringVelocity:0.0 options:0 animations:^{
        CGRect fromVCRect = fromVC.view.frame;
        fromVCRect.origin.y = originatingBurstViewRect.origin.y - 500.0;
        fromVC.view.frame = fromVCRect;
        
        CGRect topSnapshotFrame = self.topSnapshotView.frame;
        topSnapshotFrame.origin.y = 0.0;
        self.topSnapshotView.frame = topSnapshotFrame;
        self.topSnapshotView.alpha = 1.0;
        
        rangePickerView.frame = originatingBurstViewRect;
        
        CGRect bottomSnapshotFrame = self.bottomSnapshotView.frame;
        bottomSnapshotFrame.origin.y = containerView.bounds.size.height - self.bottomSnapshotView.bounds.size.height;
        self.bottomSnapshotView.frame = bottomSnapshotFrame;
        self.bottomSnapshotView.alpha = 1.0;
        
        [toVC.view setTransform:CGAffineTransformIdentity];
        
        [fromVC display:NO];

    } completion:^(BOOL finished) {
        [containerView addSubview:toVC.view];
        
        [toVC.view setTransform:CGAffineTransformIdentity];
        [toVC returnRangePickerView:rangePickerView forBurstGroup:self.burstGroup];

        [transitionContext completeTransition:YES];
    }];
}

@end
