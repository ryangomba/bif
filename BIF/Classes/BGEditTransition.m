// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGEditTransition.h"

#import "RGGeometry.h"
#import "BGBurstPreviewViewController.h"
#import "BIFHelpers.h"

#define kVCMinScale 1.0

@interface BGEditTransition ()<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) CGRect originatingRect;
@property (nonatomic, assign) CGRect finalRect;

@property (nonatomic, weak) UIView *mediaView;
@property (nonatomic, weak) UIView *mediaViewSuperview;

@property (nonatomic, strong) UIView *topSnapshotView;
@property (nonatomic, strong) UIView *centerSnapshotView;
@property (nonatomic, strong) UIView *bottomSnapshotView;

@property (nonatomic, assign) BOOL isPresenting;

@end


@implementation BGEditTransition

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithOriginatingRect:(CGRect)originatingRect
                              finalRect:(CGRect)finalRect
                              mediaView:(UIView *)mediaView {
    
    if (self = [super init]) {
        self.originatingRect = originatingRect;
        self.finalRect = finalRect;
        self.mediaView = mediaView;
        self.mediaViewSuperview = mediaView.superview;
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
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    BGBurstPreviewViewController *toVC = (id)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    containerView.backgroundColor = kBGBackgroundColor;

    CGRect topSnapshotRect = CGRectMake(0.0, 0.0, fromVC.view.bounds.size.width, self.originatingRect.origin.y);
    UIView *topSnapshotView = [fromVC.view resizableSnapshotViewFromRect:topSnapshotRect afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    topSnapshotView.frame = topSnapshotRect;
    self.topSnapshotView = topSnapshotView;

    CGRect centerSnapshotRect = self.originatingRect;
    UIView *centerSnapshotView = [fromVC.view resizableSnapshotViewFromRect:centerSnapshotRect afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    centerSnapshotView.frame = centerSnapshotRect;
    self.centerSnapshotView = centerSnapshotView;
    
    CGRect bottomSnapshotRect = CGRectMake(0.0, CGRectGetMaxY(self.originatingRect), fromVC.view.bounds.size.width, fromVC.view.bounds.size.height - CGRectGetMaxY(self.originatingRect));
    UIView *bottomSnapshotView = [fromVC.view resizableSnapshotViewFromRect:bottomSnapshotRect afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    bottomSnapshotView.frame = bottomSnapshotRect;
    self.bottomSnapshotView = bottomSnapshotView;
    
    [containerView addSubview:topSnapshotView];
    [containerView addSubview:bottomSnapshotView];
    
    [fromVC.view removeFromSuperview];
    
    CGRect toVCRect = toVC.view.frame;
    toVCRect.origin.y = self.originatingRect.origin.y - 500.0;
    toVC.view.frame = toVCRect;
    
    UIView *overlayView = [[UIView alloc] initWithFrame:containerView.bounds];
    [overlayView setBackgroundColor:[UIColor blackColor]];
//    [containerView addSubview:overlayView];
    [overlayView setAlpha:0.0];

    [containerView addSubview:toVC.view];
//    toVC.view.alpha = 0.0;
    [toVC display:NO];
    
    [containerView addSubview:centerSnapshotView];
    
    toVC.view.backgroundColor = [UIColor clearColor];
    
//    [containerView addSubview:self.mediaView];
//    self.mediaView.center = CGRectGetMidPoint(self.originatingRect);
    self.mediaView.alpha = 0.0;
    self.mediaView.transform = CGAffineTransformMakeScale(0.5, 0.5);

    CGFloat duration = [self animationDuration] * [transitionContext isAnimated];

    [UIView animateWithDuration:duration - 0.25 delay:0.25 usingSpringWithDamping:0.85 initialSpringVelocity:0.0 options:0 animations:^{
        self.mediaView.alpha = 1.0;
        self.mediaView.transform = CGAffineTransformMakeScale(0.975, 0.975);
    } completion:nil];
//    [UIView animateWithDuration:duration / 2 delay:duration / 2 options:0 animations:^{
//
//    } completion:^(BOOL finished) {
//    }];
    
//    [UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.85 initialSpringVelocity:0.0 options:0 animations:^{
        [overlayView setAlpha:1.0];
        
        toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
        
        [fromVC.view setTransform:CGAffineTransformMakeScale(kVCMinScale, kVCMinScale)];

        CGRect topSnapshotFrame = topSnapshotView.frame;
        topSnapshotFrame.origin.y = -topSnapshotView.bounds.size.height;
        topSnapshotView.frame = topSnapshotFrame;
        topSnapshotView.alpha = 0.0;
        
        CGRect centerSnapshotFrame = centerSnapshotView.frame;
        centerSnapshotFrame.origin.y = 500.0;
        centerSnapshotView.frame = centerSnapshotFrame;
        
        CGRect bottomSnapshotFrame = bottomSnapshotView.frame;
        bottomSnapshotFrame.origin.y = containerView.bounds.size.height;
        bottomSnapshotView.frame = bottomSnapshotFrame;
        bottomSnapshotView.alpha = 0.0;
        
//        toVC.view.alpha = 1.0;
        [toVC display:YES];
        
//        self.mediaView.center = CGRectGetMidPoint(self.finalRect);
//        self.mediaView.transform = CGAffineTransformIdentity;

    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
        [fromVC.view setTransform:CGAffineTransformIdentity];

        toVC.view.backgroundColor = kBGBackgroundColor;
        [self.mediaViewSuperview addSubview:self.mediaView];
        
        [transitionContext completeTransition:YES];
    }];
}

- (void)animateDismissTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    BGBurstPreviewViewController *fromVC = (id)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];

    UIView *overlayView = [[UIView alloc] initWithFrame:containerView.bounds];
    [overlayView setBackgroundColor:[UIColor blackColor]];

//    [containerView insertSubview:overlayView atIndex:0];
    [toVC.view setTransform:CGAffineTransformMakeScale(kVCMinScale, kVCMinScale)];

    CGFloat duration = [self animationDuration] * [transitionContext isAnimated];

    fromVC.view.backgroundColor = [UIColor clearColor];
    
    [UIView animateWithDuration:duration / 2 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:0 animations:^{
        self.mediaView.alpha = 0.0;
        self.mediaView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:nil];
    
//    [UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.85 initialSpringVelocity:0.0 options:0 animations:^{
        CGRect fromVCRect = fromVC.view.frame;
        fromVCRect.origin.y = self.originatingRect.origin.y - 500.0;
        fromVC.view.frame = fromVCRect;
        
        CGRect topSnapshotFrame = self.topSnapshotView.frame;
        topSnapshotFrame.origin.y = 0.0;
        self.topSnapshotView.frame = topSnapshotFrame;
        self.topSnapshotView.alpha = 1.0;
        
        self.centerSnapshotView.frame = self.originatingRect;
        
        CGRect bottomSnapshotFrame = self.bottomSnapshotView.frame;
        bottomSnapshotFrame.origin.y = containerView.bounds.size.height - self.bottomSnapshotView.bounds.size.height;
        self.bottomSnapshotView.frame = bottomSnapshotFrame;
        self.bottomSnapshotView.alpha = 1.0;
        
        [toVC.view setTransform:CGAffineTransformIdentity];
        [overlayView setAlpha:0.0];
        
        [fromVC display:NO];

    } completion:^(BOOL finished) {
        [containerView addSubview:toVC.view];
        
        [overlayView removeFromSuperview];
        [toVC.view setTransform:CGAffineTransformIdentity];

        [transitionContext completeTransition:YES];
    }];
}

@end
