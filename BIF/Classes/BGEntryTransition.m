// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGEntryTransition.h"

@interface BGEntryTransition ()<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isPresenting;

@end

@implementation BGEntryTransition

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
    return 1.3;
}

- (void)animatePresentTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = (id)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = (id)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    CGRect toVCViewRect = toVC.view.frame;
    toVCViewRect.origin.y = containerView.bounds.size.height;
    toVC.view.frame = toVCViewRect;
    [containerView addSubview:toVC.view];
    
    [UIView animateWithDuration:[self animationDuration] - 0.3 delay:0.3 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:0 animations:^{
        CGRect toVCViewRect = toVC.view.frame;
        toVCViewRect.origin.y = 0.0;
        toVC.view.frame = toVCViewRect;
        
        CGRect fromVCViewRect = fromVC.view.frame;
        fromVCViewRect.origin.y = -containerView.bounds.size.height;
        fromVC.view.frame = fromVCViewRect;
        
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

- (void)animateDismissTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    // should never happen
    [transitionContext completeTransition:YES];
}

@end
