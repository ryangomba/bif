//
//  BGBurstGroupRangePickerView.m
//  BurstGIF
//
//  Created by Ryan Gomba on 6/8/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGBurstGroupRangePicker.h"

#import <Photos/Photos.h>
#import "BGBurstGroupView.h"

static CGFloat const kHandleTouchWidth = 44.0;
static CGFloat const kHandleWidth = 4.0;

@interface BGBurstGroupRangePicker ()

@property (nonatomic, strong) BGBurstGroupView *burstGroupView;

@property (nonatomic, strong) UIView *startHandle;
@property (nonatomic, strong) UIView *endHandle;

@end

@implementation BGBurstGroupRangePicker

- (instancetype)initWithFrame:(CGRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.burstGroupView = [[BGBurstGroupView alloc] initWithFrame:self.bounds];
        self.burstGroupView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.burstGroupView];
        
        [self addSubview:self.startHandle];
        [self addSubview:self.endHandle];
    }
    return self;
}

- (void)setBurstGroup:(BGBurstGroup *)burstGroup {
    if (burstGroup == _burstGroup) {
        return;
    }
    
    _burstGroup = burstGroup;
    
    self.burstGroupView.assets = burstGroup.photos;
}

- (UIView *)newHandle {
    CGFloat handleHeight = self.frame.size.height;
    
    CGRect handleContainerRect = CGRectMake(0.0, 0.0, kHandleTouchWidth, handleHeight);
    UIView *handleContainer = [[UIView alloc] initWithFrame:handleContainerRect];
    handleContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    CGFloat handleInsetX = (kHandleTouchWidth - kHandleWidth) / 2.0;
    CGRect handleRect = CGRectMake(handleInsetX, 0.0, kHandleWidth, handleHeight);
    UIView *handle = [[UIView alloc] initWithFrame:handleRect];
    handle.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    handle.backgroundColor = [UIColor blueColor];
    [handleContainer addSubview:handle];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] init];
    [pan addTarget:self action:@selector(onPan:)];
    [handleContainer addGestureRecognizer:pan];

    return handleContainer;
}

- (UIView *)startHandle {
    if (!_startHandle) {
        _startHandle = [self newHandle];
    }
    return _startHandle;
}

- (UIView *)endHandle {
    if (!_endHandle) {
        _endHandle = [self newHandle];
    }
    return _endHandle;
}

- (void)onPan:(UIPanGestureRecognizer *)recognizer {
    static CGPoint startCenter;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            startCenter = recognizer.view.center;
            [self.delegate burstGroupRangePickerDidBeginAdjustingRange:self];
        } break;
            
        case UIGestureRecognizerStateChanged: {
            CGPoint newCenter = startCenter;
            newCenter.x += [recognizer translationInView:self].x;
            recognizer.view.center = newCenter;
            [self updateFrameIDs];
        } break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self.delegate burstGroupRangePickerDidEndAdjustingRange:self];
        } break;
            
        default:
            break;
    }
}

- (CGFloat)relativePositionForFrameID:(NSString *)frameID defaultValue:(CGFloat)defaultValue {
    __block CGFloat relativePosition = defaultValue;
    [self.burstGroup.photos enumerateObjectsUsingBlock:
     ^(PHAsset *asset, NSUInteger i, BOOL *stop) {
         if ([asset.localIdentifier isEqualToString:frameID]) {
             relativePosition = i / (CGFloat)MAX(self.burstGroup.photos.count - 1, 1);
             *stop = YES;
         }
     }];
    return relativePosition;
}

- (NSString *)frameIDForRelativePosition:(CGFloat)relativePosition index:(NSUInteger *)index {
    *index = self.burstGroup.photos.count * MIN(relativePosition, 0.99);
    PHAsset *asset = self.burstGroup.photos[*index];
    return asset.localIdentifier;
}

- (void)updateStartHandlePosition {
    NSString *frameID = self.burstGroup.burstInfo.startFrameIdentifier;
    [self updatePositionForHandle:self.startHandle frameID:frameID defaultPosition:0.0];
}

- (void)updateEndHandlePosition {
    NSString *frameID = self.burstGroup.burstInfo.endFrameIdentifier;
    [self updatePositionForHandle:self.endHandle frameID:frameID defaultPosition:1.0];
}

- (void)updatePositionForHandle:(UIView *)handle
                        frameID:(NSString *)frameID
                defaultPosition:(CGFloat)defaultPosition {
    
    CGFloat position = [self relativePositionForFrameID:frameID defaultValue:defaultPosition];
    CGFloat x = self.bounds.size.width * position;
    CGPoint center = CGPointMake(x, self.bounds.size.height / 2.0);
    handle.center = center;
}

- (void)updateFrameIDs {
    BOOL updated = NO;
    NSUInteger changedIndex = 0;
    
    NSUInteger startFrameIndex;
    CGFloat startPosition = self.startHandle.center.x / self.bounds.size.width;
    NSString *newStartFrameID = [self frameIDForRelativePosition:startPosition index:&startFrameIndex];
    if (![self.burstGroup.burstInfo.startFrameIdentifier isEqualToString:newStartFrameID]) {
        self.burstGroup.burstInfo.startFrameIdentifier = newStartFrameID;
        changedIndex = startFrameIndex;
        updated = YES;
    }
    
    NSUInteger endFrameIndex;
    CGFloat endPosition = self.endHandle.center.x / self.bounds.size.width;
    NSString *endFrameID = [self frameIDForRelativePosition:endPosition index:&endFrameIndex];
    if (![self.burstGroup.burstInfo.endFrameIdentifier isEqualToString:endFrameID]) {
        self.burstGroup.burstInfo.endFrameIdentifier = endFrameID;
        changedIndex = endFrameIndex;
        updated = YES;
    }
    
    [self updateStartHandlePosition];
    [self updateEndHandlePosition];
    
    if (updated) {
        [self.delegate burstGroupRangePickerDidUpdateRange:self frameIndex:changedIndex];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateStartHandlePosition];
    [self updateEndHandlePosition];
}

@end
