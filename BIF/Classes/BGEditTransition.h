// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGEditTransition : NSObject<UIViewControllerTransitioningDelegate>

- (instancetype)initWithOriginatingRect:(CGRect)originatingRect
                              finalRect:(CGRect)finalRect
                              mediaView:(UIView *)mediaView;

@end
