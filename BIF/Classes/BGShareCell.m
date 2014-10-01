// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGShareCell.h"

#import "BIFHelpers.h"
#import "BGPieProgressView.h"

static CGFloat const kIconSize = 36.0;
static CGFloat const kProgressPieSize = 18.0;
static CGFloat const kIconHorizontalInset = 30.0;

@interface BGShareCell ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *imageView;
//@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) BGPieProgressView *progressView;
@property (nonatomic, strong) UIImageView *chevronView;

@end

@implementation BGShareCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.textLabel];

        self.shareState = BGShareCellStateNormal;
    }
    return self;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _textLabel.font = [UIFont fontWithName:@"ProximaNovaSoft-Medium" size:16.0];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        
        _textLabel.layer.borderWidth = 1.0;
    }
    return _textLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeCenter;
    }
    return _imageView;
}

- (UIImageView *)chevronView {
    if (!_chevronView) {
        _chevronView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, kIconSize, kIconSize)];
        _chevronView.contentMode = UIViewContentModeCenter;
        _chevronView.image = [[UIImage imageNamed:@"chevronGlyph"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return _chevronView;
}

//- (UIActivityIndicatorView *)spinner {
//    if (!_spinner) {
//        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//        [_spinner startAnimating];
//    }
//    return _spinner;
//}

- (BGPieProgressView *)progressView {
    if (!_progressView) {
        CGRect progressViewRect = CGRectMake(0.0, 0.0, kProgressPieSize, kProgressPieSize);
        _progressView = [[BGPieProgressView alloc] initWithFrame:progressViewRect];
    }
    return _progressView;
}

- (void)setShareProgress:(CGFloat)shareProgress {
    _shareProgress = shareProgress;
    
    self.progressView.progress = shareProgress;
}

- (void)setDefaultTitle:(NSString *)defaultTitle
           workingTitle:(NSString *)workingTitle
           successTitle:(NSString *)successTitle
              imageName:(NSString *)imageName {
    
    self.defaultTitle = defaultTitle;
    self.workingTitle = workingTitle;
    self.successTitle = successTitle;
    
    self.textLabel.text = defaultTitle;
    self.imageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [self setNeedsLayout];
}

- (void)setShareState:(BGShareCellState)shareState {
    _shareState = shareState;
    
    NSString *text;
    BOOL showSpinner;
    BOOL showChevron;
    UIColor *color;
    
    switch (shareState) {
        case BGShareCellStateNormal:
            text = self.defaultTitle;
            showSpinner = NO;
            showChevron = NO;
            color = [UIColor whiteColor];
            break;
            
        case BGShareCellStateSharing:
            text = self.workingTitle;
            showSpinner = YES;
            showChevron = NO;
            color = HEX_COLOR(0x72daff);
            break;
            
        case BGShareCellStateShared:
            text = self.successTitle;
            showSpinner = NO;
            showChevron = YES;
            color = HEX_COLOR(0x73ff7c);
            break;
    }
    
    self.textLabel.text = text;
    
    self.textLabel.textColor = color;
    self.textLabel.layer.borderColor = color.CGColor;
    self.imageView.tintColor = color;
    self.imageView.layer.borderColor = color.CGColor;
//    self.progressView.color = color;
    self.chevronView.tintColor = color;
    
    if (showSpinner) {
        [self.imageView removeFromSuperview];
//        [self.contentView addSubview:self.spinner];
        [self.contentView addSubview:self.progressView];
    } else {
//        [self.spinner removeFromSuperview];
        [self.progressView removeFromSuperview];
        [self.contentView addSubview:self.imageView];
    }
    
    if (showChevron) {
        [self.contentView addSubview:self.chevronView];
    } else {
        [self.chevronView removeFromSuperview];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.defaultTitle.length > 0) {
        self.textLabel.frame = self.contentView.bounds;
        self.textLabel.layer.cornerRadius = self.contentView.bounds.size.height / 2.0;
        self.textLabel.hidden = NO;
        
        CGFloat accessoryY = self.contentView.bounds.size.height / 2.0;
        CGPoint accessoryCenter = CGPointMake(kIconHorizontalInset, accessoryY);
        self.imageView.frame = CGRectMake(0.0, 0.0, kIconSize, kIconSize);
        self.imageView.center = accessoryCenter;
//        self.spinner.center = accessoryCenter;
        self.progressView.center = accessoryCenter;
        self.imageView.layer.borderWidth = 0.0;
        
        CGFloat chevronX = self.contentView.bounds.size.width - kIconHorizontalInset;
        CGPoint chevronCenter = CGPointMake(chevronX, accessoryY);
        self.chevronView.center = chevronCenter;
        
    } else {
        self.textLabel.hidden = YES;
        
        CGFloat imageViewSize = MIN(self.bounds.size.height, self.bounds.size.width);
        CGFloat imageViewX = (self.bounds.size.width - imageViewSize) / 2.0;
        CGFloat imageViewY = (self.bounds.size.height - imageViewSize) / 2.0;
        self.imageView.frame = CGRectMake(imageViewX, imageViewY, imageViewSize, imageViewSize);
        self.imageView.layer.cornerRadius = imageViewSize / 2.0;
        self.imageView.layer.borderWidth = 1.0;
    }
}

//#pragma mark -
//#pragma mark UIControl
//
//- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
//    [self scaleUp:NO withVelocity:NO];
//    
//    return [super beginTrackingWithTouch:touch withEvent:event];
//}
//
//- (void)cancelTrackingWithEvent:(UIEvent *)event {
//    [super cancelTrackingWithEvent:event];
//    
//    [self scaleUp:YES withVelocity:NO];
//}
//
//- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
//    [super endTrackingWithTouch:touch withEvent:event];
//    
//    if (CGRectContainsPoint(self.bounds, [touch locationInView:self])) {
//        [self scaleUp:YES withVelocity:YES];
//    } else {
//        [self scaleUp:YES withVelocity:NO];
//    }
//}
//
//
//#pragma mark -
//#pragma mark Animation
//
//- (void)scaleUp:(BOOL)up withVelocity:(BOOL)withVelocity {
//    CGFloat scaleDiff = 0.1;
//    CGFloat toValue = up ? 1.0 : 1.0 - scaleDiff;
//    CGFloat normalizedScale = (1.0 - self.currentScale) / scaleDiff;
//    CGFloat velocity = withVelocity * (1.0 - normalizedScale) * -2.0;
//    
//    if (self.spring) {
//        [self.spring setTargetValue:toValue];
//        [self.spring setVelocity:velocity];
//        
//    } else {
//        IGDynamicsProperties *properties = [IGDynamicsProperties bouncy1DProperties];
//        [properties setDamping:0.188];
//        
//        weakify(self);
//        IGDynamics1D *spring =
//        [IGDynamics springFromValue:self.currentScale
//                            toValue:toValue
//                 dynamicsProperties:properties
//                    initialVelocity:velocity
//                      withStepBlock:^(CGFloat value, BOOL *stop)
//         {
//             strongify(self);
//             [self setCurrentScale:value];
//             [self.springContentView setTransform:CGAffineTransformMakeScale(value, value)];
//         }
//                         completion:nil];
//        [self setSpring:spring];
//    }
//}

@end
