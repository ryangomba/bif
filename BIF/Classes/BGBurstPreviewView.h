// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstInfo.h" // TODO don't like

@interface BGBurstPreviewView : UIView

@property (nonatomic, strong) NSArray *assets;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign) CGFloat framesPerSecond;
@property (nonatomic, assign) LoopMode loopMode;

@property (nonatomic, assign) NSUInteger staticIndex;
@property (nonatomic, assign) BOOL animated;

- (NSArray *)allImagesInRangeWithLoopModeApplied;

@end
