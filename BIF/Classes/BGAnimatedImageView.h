// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGAnimatedImageView : UIView

@property (nonatomic, strong) NSArray *imagePaths;
@property (nonatomic, assign) CGFloat framesPerSecond;
@property (nonatomic, assign) BOOL animated;

@property (nonatomic, assign, readonly) NSInteger frameIndex;

@end
