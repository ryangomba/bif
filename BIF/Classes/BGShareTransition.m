// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGShareTransition.h"

#import <RGImage/UIImage+ImageEffects.h>

@interface BGShareTransition ()<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isPresenting;

@property (nonatomic, strong) UIImageView *snapshotView;

@end

@implementation BGShareTransition

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
#pragma mark Helpers

- (UIImage *)imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    CGRect contextRect = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
    [view drawViewHierarchyInRect:contextRect afterScreenUpdates:YES];
    
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


#pragma mark -
#pragma mark Private

- (CGFloat)animationDuration {
    return self.isPresenting ? 0.5 : 0.8;
}

- (void)animatePresentTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = (id)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = (id)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    UIImage *fromVCSnapshot = [self imageWithView:fromVC.view];
    UIImage *blurredBackgroundImage = [fromVCSnapshot applyCustomDarkEffect];
    self.snapshotView = [[UIImageView alloc] initWithImage:blurredBackgroundImage];
    [containerView addSubview:self.snapshotView];
    
    [containerView addSubview:toVC.view];
    
    self.snapshotView.alpha = 0.0;
    toVC.view.alpha = 0.0;
    
    [UIView animateWithDuration:[self animationDuration] animations:^{
        self.snapshotView.alpha = 1.0;
        toVC.view.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

- (void)animateDismissTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = (id)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = (id)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    [containerView insertSubview:toVC.view atIndex:0];
    
    [UIView animateWithDuration:[self animationDuration] / 2.0 delay:[self animationDuration] / 2.0 options:0 animations:^{
        self.snapshotView.alpha = 0.0;
        fromVC.view.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        [fromVC.view removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

@end
