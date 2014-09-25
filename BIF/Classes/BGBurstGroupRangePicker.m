// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupRangePicker.h"

@import Photos;

#import "BGBurstGroupView.h"

static CGFloat const kHandleTouchWidth = 44.0;
static CGFloat const kHandleTouchHeight = 66.0;
static CGFloat const kHandleWidth = 22.0;
static CGFloat const kHandleHeight = 32.0;
static CGFloat const kMinimumRelativeBurstLength = 0.2;

@interface BGBurstGroupRangePicker ()

@property (nonatomic, strong) UIView *startHandle;
@property (nonatomic, strong) UIView *endHandle;

@end

@implementation BGBurstGroupRangePicker

- (instancetype)initWithFrame:(CGRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self addSubview:self.startHandle];
        [self addSubview:self.endHandle];
    }
    return self;
}

- (void)setBurstGroupView:(BGBurstGroupView *)burstGroupView {
    _burstGroupView = burstGroupView;
    
    _burstGroupView.frame = self.bounds;
    self.burstGroupView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.burstGroupView.layer.cornerRadius = 4.0;
    self.burstGroupView.layer.masksToBounds = YES;
    [self insertSubview:self.burstGroupView atIndex:0];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGFloat handleInsetX = (kHandleTouchWidth - kHandleWidth) / 2.0;
    CGFloat handleInsetY = (kHandleTouchHeight - self.bounds.size.height) / 2.0;
    return CGRectContainsPoint(CGRectInset(self.bounds, -handleInsetX, -handleInsetY), point);
}

- (UIView *)newHandleWithImageName:(NSString *)imageName {
    CGRect handleContainerRect = CGRectMake(0.0, 0.0, kHandleTouchWidth, kHandleTouchHeight);
    UIView *handleContainer = [[UIView alloc] initWithFrame:handleContainerRect];
    
    CGFloat handleInsetX = (kHandleTouchWidth - kHandleWidth) / 2.0;
    CGFloat handleInsetY = (kHandleTouchHeight - kHandleHeight) / 2.0;
    CGRect handleRect = CGRectMake(handleInsetX, handleInsetY, kHandleWidth, kHandleHeight);
    UIImageView *handle = [[UIImageView alloc] initWithFrame:handleRect];
    handle.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    handle.image = [UIImage imageNamed:imageName];
    [handleContainer addSubview:handle];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] init];
    [pan addTarget:self action:@selector(onPan:)];
    [handleContainer addGestureRecognizer:pan];

    return handleContainer;
}

- (UIView *)startHandle {
    if (!_startHandle) {
        _startHandle = [self newHandleWithImageName:@"startHandle"];
    }
    return _startHandle;
}

- (UIView *)endHandle {
    if (!_endHandle) {
        _endHandle = [self newHandleWithImageName:@"endHandle"];
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
            [self updateFrameIDsWithDesiredCenter:newCenter forHandle:recognizer.view];
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
    CGFloat x = kHandleWidth / 2.0 + (self.bounds.size.width - kHandleWidth) * position;
    CGPoint center = CGPointMake(x, self.bounds.size.height / 2.0);
    handle.center = center;
}

- (void)updateFrameIDsWithDesiredCenter:(CGPoint)desiredCenter forHandle:(UIView *)movedHandle {
    BOOL updated = NO;
    NSUInteger changedIndex = 0;
    
    NSUInteger startFrameIndex;
    CGPoint startHandleCenter = [movedHandle isEqual:self.startHandle] ? desiredCenter : self.startHandle.center;
    CGFloat startPosition = (startHandleCenter.x - kHandleWidth / 2.0) / (self.bounds.size.width - kHandleWidth);
    NSString *newStartFrameID = [self frameIDForRelativePosition:startPosition index:&startFrameIndex];
    
    NSUInteger endFrameIndex;
    CGPoint endHandleCenter = [movedHandle isEqual:self.endHandle] ? desiredCenter : self.endHandle.center;
    CGFloat endPosition = (endHandleCenter.x - kHandleWidth / 2.0) / (self.bounds.size.width - kHandleWidth);
    NSString *endFrameID = [self frameIDForRelativePosition:endPosition index:&endFrameIndex];
    
    if (ABS(startPosition - endPosition) <= kMinimumRelativeBurstLength) {
        return;
    }
    
    if (![self.burstGroup.burstInfo.startFrameIdentifier isEqualToString:newStartFrameID]) {
        self.burstGroup.burstInfo.startFrameIdentifier = newStartFrameID;
        [self updateStartHandlePosition];
        changedIndex = startFrameIndex;
        updated = YES;
    }

    if (![self.burstGroup.burstInfo.endFrameIdentifier isEqualToString:endFrameID]) {
        self.burstGroup.burstInfo.endFrameIdentifier = endFrameID;
        [self updateEndHandlePosition];
        changedIndex = endFrameIndex;
        updated = YES;
    }
    
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
