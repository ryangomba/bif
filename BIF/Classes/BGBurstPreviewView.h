//
//  CHBurstPreviewView.h
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <UIKit/UIKit.h>
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
