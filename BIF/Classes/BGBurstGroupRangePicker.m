// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupRangePicker.h"

@import Photos;

#import "BGBurstGroupView.h"

static CGFloat const kHandleTouchWidth = 44.0;
static CGFloat const kHandleTouchHeight = 88.0;
static CGFloat const kHandleWidth = 22.0;
static CGFloat const kHandleHeight = 60.0;
static CGFloat const kMinimumRelativeBurstLength = 0.2;
static CGFloat const kCornerRadius = 4.0;

@interface BGBurstGroupRangePicker ()

@property (nonatomic, strong) BGBurstGroupView *burstGroupView;

@property (nonatomic, strong) UIView *startHandle;
@property (nonatomic, strong) UIView *endHandle;

@property (nonatomic, strong) UIView *leftTrimOverlayView;
@property (nonatomic, strong) UIView *rightTrimOverlayView;
@property (nonatomic, strong) UIView *centerTrimOverlayView;

@end

@implementation BGBurstGroupRangePicker

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius = kCornerRadius;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = 1.0;
        
        [self addSubview:self.burstGroupView];
        
        [self.burstGroupView addSubview:self.leftTrimOverlayView];
        [self.burstGroupView addSubview:self.rightTrimOverlayView];
        [self.burstGroupView addSubview:self.centerTrimOverlayView];
        
        [self addSubview:self.startHandle];
        [self addSubview:self.endHandle];
        
        [self setEditable:NO animated:NO];
    }
    return self;
}

- (void)setBurstGroup:(BGBurstGroup *)burstGroup {
    _burstGroup = burstGroup;
    
    self.burstGroupView.photos = burstGroup.photos;
}

- (void)setEditable:(BOOL)editable animated:(BOOL)animated {
    [self updateStartHandlePosition];
    [self updateEndHandlePosition];
    
    BOOL editViewAlpha = editable ? 1.0 : 0.0;
    
    void(^animationBlock)(void) = ^{
        self.leftTrimOverlayView.alpha = editViewAlpha;
        self.rightTrimOverlayView.alpha = editViewAlpha;
        self.centerTrimOverlayView.alpha = editViewAlpha;
        self.startHandle.alpha = editViewAlpha;
        self.endHandle.alpha = editViewAlpha;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:animationBlock];
    } else {
        animationBlock();
    }
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

- (BGBurstGroupView *)burstGroupView {
    if (!_burstGroupView) {
        _burstGroupView = [[BGBurstGroupView alloc] initWithFrame:self.bounds];
        _burstGroupView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        _burstGroupView.layer.cornerRadius = kCornerRadius;
        _burstGroupView.layer.masksToBounds = YES;
        
        _burstGroupView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        _burstGroupView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return _burstGroupView;
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

- (UIView *)leftTrimOverlayView {
    if (!_leftTrimOverlayView) {
        _leftTrimOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, kHandleHeight)];
        _leftTrimOverlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    }
    return _leftTrimOverlayView;
}

- (UIView *)rightTrimOverlayView {
    if (!_rightTrimOverlayView) {
        _rightTrimOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, kHandleHeight)];
        _rightTrimOverlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    }
    return _rightTrimOverlayView;
}

- (UIView *)centerTrimOverlayView {
    if (!_centerTrimOverlayView) {
        _centerTrimOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -1.0, 0.0, kHandleHeight + 2.0)];
        _centerTrimOverlayView.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.25].CGColor;
        _centerTrimOverlayView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return _centerTrimOverlayView;
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
    NSString *frameID = self.burstGroup.startFrameIdentifier;
    [self updatePositionForHandle:self.startHandle frameID:frameID defaultPosition:0.0];
}

- (void)updateEndHandlePosition {
    NSString *frameID = self.burstGroup.endFrameIdentifier;
    [self updatePositionForHandle:self.endHandle frameID:frameID defaultPosition:1.0];
}

- (void)updatePositionForHandle:(UIView *)handle
                        frameID:(NSString *)frameID
                defaultPosition:(CGFloat)defaultPosition {
    
    CGFloat position = [self relativePositionForFrameID:frameID defaultValue:defaultPosition];
    CGFloat x = kHandleWidth / 2.0 + (self.bounds.size.width - kHandleWidth) * position;
    CGPoint center = CGPointMake(x, self.bounds.size.height / 2.0);
    handle.center = center;
    
    [self updateOverlayViewPositions];
}

- (void)updateOverlayViewPositions {
    CGFloat startX = CGRectGetMaxX(self.startHandle.frame) - (kHandleTouchWidth - kHandleWidth) / 2;
    CGFloat endX = CGRectGetMinX(self.endHandle.frame) + (kHandleTouchWidth - kHandleWidth) / 2;
    
    CGRect leftOverlayRect = self.leftTrimOverlayView.frame;
    leftOverlayRect.size.width = startX;
    self.leftTrimOverlayView.frame = leftOverlayRect;
    
    CGRect rightOverlayRect = self.rightTrimOverlayView.frame;
    rightOverlayRect.origin.x = endX;
    rightOverlayRect.size.width = self.bounds.size.width - endX;
    self.rightTrimOverlayView.frame = rightOverlayRect;
    
    CGRect centerOverlayRect = self.centerTrimOverlayView.frame;
    centerOverlayRect.origin.x = startX;
    centerOverlayRect.size.width = endX - startX;
    self.centerTrimOverlayView.frame = centerOverlayRect;
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
    
    if (![self.burstGroup.startFrameIdentifier isEqualToString:newStartFrameID]) {
        self.burstGroup.startFrameIdentifier = newStartFrameID;
        [self updateStartHandlePosition];
        changedIndex = startFrameIndex;
        updated = YES;
    }

    if (![self.burstGroup.endFrameIdentifier isEqualToString:endFrameID]) {
        self.burstGroup.endFrameIdentifier = endFrameID;
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
    
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:kCornerRadius].CGPath;
}

@end
