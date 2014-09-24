// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGEditTransition.h"

@interface BGEditTransition ()<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isPresenting;

@end


@implementation BGEditTransition

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
    return self.isPresenting ? 0.3 : 0.3;
}

- (void)animatePresentTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];

    UIView *overlayView = [[UIView alloc] initWithFrame:containerView.bounds];
    [overlayView setBackgroundColor:[UIColor blackColor]];
    [containerView addSubview:overlayView];

    [containerView addSubview:toVC.view];
    CGRect toVCViewFrame = toVC.view.frame;
    toVCViewFrame.origin.y = containerView.bounds.size.height;
    toVC.view.frame = toVCViewFrame;
    [overlayView setAlpha:0.0];

    CGFloat duration = [self animationDuration] * [transitionContext isAnimated];

    [UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
        [fromVC.view setTransform:CGAffineTransformMakeScale(0.95, 0.95)];
        [overlayView setAlpha:1.0];
        CGRect toVCViewFrame = toVC.view.frame;
        toVCViewFrame.origin.y = 0.0;
        toVC.view.frame = toVCViewFrame;

    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
        [fromVC.view setTransform:CGAffineTransformIdentity];

        [transitionContext completeTransition:YES];
    }];
}

- (void)animateDismissTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];

    UIView *overlayView = [[UIView alloc] initWithFrame:containerView.bounds];
    [overlayView setBackgroundColor:[UIColor blackColor]];

    [containerView insertSubview:overlayView atIndex:0];
    [containerView insertSubview:toVC.view atIndex:0];
    [toVC.view setTransform:CGAffineTransformMakeScale(0.95, 0.95)];

    CGFloat duration = [self animationDuration] * [transitionContext isAnimated];

    [UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
        CGRect fromVCViewFrame = fromVC.view.frame;
        fromVCViewFrame.origin.y = containerView.bounds.size.height;
        fromVC.view.frame = fromVCViewFrame;
        [toVC.view setTransform:CGAffineTransformIdentity];
        [overlayView setAlpha:0.0];

    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
        [toVC.view setTransform:CGAffineTransformIdentity];

        [transitionContext completeTransition:YES];
    }];
}

@end
