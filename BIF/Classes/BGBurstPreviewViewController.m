// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstPreviewViewController.h"

#import "BGBurstGroupRangePicker.h"
#import "BGBurstPreviewView.h"
#import "BGGIFMaker.h"
#import "BGDatabase.h"
#import "BIFHelpers.h"
#import "BGTextView.h"
#import "BGShareViewController.h"
#import "BGTextButton.h"
#import "BGShareTransition.h"
#import "BGFinalizedBurst.h"

static CGFloat const kButtonSize = 56.0;
static CGFloat const kRangePickerHeight = 60.0;
static CGFloat const kPreviewPadding = 10.0;
static CGFloat const kSliderPadding = 36.0;

@interface BGBurstPreviewViewController ()<BGBurstGroupRangePickerDelegate, UITextViewDelegate, BGTextViewDelegate, BGBurstPreviewViewDelegate, BGShareViewControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) BGBurstGroup *burstGroup;

@property (nonatomic, strong) UIScrollView *containerView;

@property (nonatomic, strong, readwrite) BGBurstPreviewView *previewView;

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) BGTextButton *backButton;
@property (nonatomic, strong) BGTextButton *shareButton;

@property (nonatomic, strong) BGTextView *textView;
@property (nonatomic, strong) UILabel *textHintLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *textPanRecognizer;
@property (nonatomic, strong) UILabel *watermarkLabel;

@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) BGBurstGroupRangePicker *rangePicker;
@property (nonatomic, strong) UITapGestureRecognizer *rangePickerTapRecognizer;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) BGTextButton *repeatButton;
@property (nonatomic, strong) BGTextButton *textButton;

@property (nonatomic, assign) BOOL showingText;

@property (nonatomic, strong) BGShareTransition *shareTransition;

@end


@implementation BGBurstPreviewViewController

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.burstGroup = burstGroup;
    }
    return self;
}


#pragma mark -
#pragma mark Layout Helpers

- (CGFloat)previewSize {
    return [UIScreen mainScreen].bounds.size.width - 2 * kPreviewPadding;
}

- (CGFloat)topBarHeight {
    return([UIScreen mainScreen].bounds.size.height - [self previewSize]) * 0.35;
}

- (CGFloat)bottomBarHeight {
    return([UIScreen mainScreen].bounds.size.height - [self previewSize]) * 0.65;
}

- (CGRect)normalFrameForMediaView {
    return CGRectMake(kPreviewPadding, [self topBarHeight], [self previewSize], [self previewSize]);
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = kBGBackgroundColor;
    
    self.containerView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.containerView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeInteractive];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.containerView.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height + 1.0);
    self.containerView.delegate = self;
    [self.containerView setScrollEnabled:NO];
    [self.view addSubview:self.containerView];
    
    // top bar
    
    self.topBar.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, [self topBarHeight]);
    [self.containerView addSubview:self.topBar];
    
    [self setUpTopBar];
    
    // preview area
    
    self.previewView.frame = [self normalFrameForMediaView];
    [self.containerView addSubview:self.previewView];
    
    [self.previewView addSubview:self.watermarkLabel];
    
    self.textView.frame = self.previewView.bounds;
    [self.previewView addSubview:self.textView];
    
    self.textHintLabel.alpha = 0.0;
    [self.view addSubview:self.textHintLabel];

    // bottom bar
    
    self.bottomBar.frame = CGRectMake(0.0, CGRectGetMaxY(self.previewView.frame), self.view.bounds.size.width, [self bottomBarHeight]);
    [self.view addSubview:self.bottomBar];
    
    [self setUpBottomBar];
    
    // setup
    
    self.speedSlider.value = [self sliderValueForFramesPerSecond:self.burstGroup.framesPerSecond];
    [self updateRepeatButtonForLoopMode:self.burstGroup.loopMode];
    
    self.previewView.photos = self.burstGroup.photos;
    self.previewView.framesPerSecond = self.burstGroup.framesPerSecond;
    self.previewView.loopMode = self.burstGroup.loopMode;
    self.previewView.cropInfo = self.burstGroup.cropInfo;
    
    [self updatePhotoRange];
    
    BOOL hasText = self.burstGroup.text.length > 0;
    self.textView.internalTextView.text = self.burstGroup.text;
    CGFloat textPosition = hasText ? self.burstGroup.textPosition : 0.5;
    self.showingText = hasText;
    [self updateTextPositionWithDesiredPosition:textPosition animated:NO];
    [self updateTextVisibility];
    
    self.previewView.animated = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.previewView.animated = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [BGDatabase saveBurstGroup:self.burstGroup];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Status Bar

- (BOOL)prefersStatusBarHidden {
//    return NO;
    return YES;
}


#pragma mark -
#pragma mark Bar Setup

- (void)setUpTopBar {
    CGFloat buttonWidth = 56.0; // HACK hardcoded
    CGFloat buttonHeight = MIN(self.topBar.bounds.size.height, 56.0);
    CGFloat buttonHorizontalMargin = kBGDefaultPadding;
    CGFloat buttonVerticalMargin = (self.topBar.bounds.size.height - buttonHeight) / 2;
    
    self.backButton.frame = CGRectMake(buttonHorizontalMargin, buttonVerticalMargin, buttonWidth, buttonHeight);
    [self.topBar addSubview:self.backButton];
    
    CGFloat shareButtonX = self.topBar.bounds.size.width - buttonHorizontalMargin - buttonWidth;
    self.shareButton.frame = CGRectMake(shareButtonX, buttonVerticalMargin, buttonWidth, buttonHeight);
    [self.topBar addSubview:self.shareButton];
}

- (CGFloat)verticalSpacingForBottomView {
    CGFloat contentHeight = kRangePickerHeight + kButtonSize;
    return (self.bottomBar.bounds.size.height - contentHeight) / 3;
}

- (void)setUpBottomBar {
    CGFloat verticalSpacing = [self verticalSpacingForBottomView];
    
    CGFloat rangePickerY = verticalSpacing;
    CGFloat rangePickerPadding = kBGLargePadding;
    CGFloat rangePickerWidth = self.view.bounds.size.width - 2 * rangePickerPadding;
    CGRect rangePickerRect = CGRectMake(rangePickerPadding, rangePickerY, rangePickerWidth, kRangePickerHeight);
    CGRect rangePickerViewRect = rangePickerRect;
    self.rangePicker.frame = rangePickerViewRect;
    [self.bottomBar addSubview:self.rangePicker];
    
    CGFloat buttonPadding = kBGDefaultPadding;
    CGFloat buttonY = CGRectGetMaxY(rangePickerRect) + verticalSpacing;
    CGRect textButtonRect = CGRectMake(buttonPadding, buttonY, kButtonSize, kButtonSize);
    self.textButton.frame = textButtonRect;
    [self.bottomBar addSubview:self.textButton];
    
    CGFloat speedSliderY = buttonY;
    CGFloat speedSliderX = CGRectGetMaxX(textButtonRect) + kSliderPadding;
    CGFloat speedSliderWidth = self.view.bounds.size.width - (textButtonRect.size.width + kSliderPadding + buttonPadding) * 2;
    CGRect speedSliderRect = CGRectMake(speedSliderX, speedSliderY, speedSliderWidth, kButtonSize);
    self.speedSlider.frame = speedSliderRect;
    [self.bottomBar addSubview:self.speedSlider];
    
    UIImageView *turtleView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 12.0, 12.0)];
    turtleView.image = [UIImage imageNamed:@"turtleGlyph"];
    turtleView.center = CGPointMake(-10, 28.0);
    [self.speedSlider insertSubview:turtleView atIndex:0];
    
    UIImageView *rabbitView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 12.0, 12.0)];
    rabbitView.image = [UIImage imageNamed:@"rabbitGlyph"];
    rabbitView.center = CGPointMake(speedSliderWidth + 10.0, 28.0);
    [self.speedSlider insertSubview:rabbitView atIndex:0];
    
    CGFloat repeatButtonX = self.bottomBar.bounds.size.width - buttonPadding - kButtonSize;
    CGRect repeatButtonRect = CGRectMake(repeatButtonX, buttonY, kButtonSize, kButtonSize);
    self.repeatButton.frame = repeatButtonRect;
    [self.bottomBar addSubview:self.repeatButton];
}


#pragma mark -
#pragma mark Properties

- (UIView *)topBar {
    if (!_topBar) {
        _topBar = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return _topBar;
}

- (BGTextButton *)backButton {
    if (!_backButton) {
        _backButton = [[BGTextButton alloc] initWithFrame:CGRectZero];
        [_backButton setImageNamed:@"backGlyph"];
        [_backButton setTitle:NSLocalizedString(@"Back", nil)];
        [_backButton addTarget:self
                        action:@selector(onBackButtonTapped)
              forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (BGTextButton *)shareButton {
    if (!_shareButton) {
        _shareButton = [[BGTextButton alloc] initWithFrame:CGRectZero];
        [_shareButton setImageNamed:@"shareGlyph"];
        [_shareButton setTitle:NSLocalizedString(@"Share", nil)];
        [_shareButton addTarget:self
                         action:@selector(onShareButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareButton;
}

- (BGBurstPreviewView *)previewView {
    if (!_previewView) {
        _previewView = [[BGBurstPreviewView alloc] initWithFrame:CGRectZero];
        _previewView.layer.anchorPoint = CGPointMake(0.5, 1.0);
        _previewView.backgroundColor = [UIColor whiteColor];
        _previewView.delegate = self;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [tap addTarget:self action:@selector(onPreviewViewTapped)];
        [_previewView addGestureRecognizer:tap];
    }
    return _previewView;
}

- (NSDictionary *)textAttributes {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    return @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:48.0],
        NSParagraphStyleAttributeName: paragraphStyle,
        NSStrokeColorAttributeName:[UIColor blackColor],
        NSStrokeWidthAttributeName: @(-5.0),
    };
}

- (BGTextView *)textView {
    if (!_textView) {
        _textView = [[BGTextView alloc] initWithFrame:CGRectZero];
        
        _textView.internalTextView.attributedText =
        [[NSAttributedString alloc] initWithString:@"placeholder" attributes:self.textAttributes];
        
        [_textView addGestureRecognizer:self.textPanRecognizer];
        
        _textView.internalTextView.textContainer.maximumNumberOfLines = 4;
        _textView.internalTextView.returnKeyType = UIReturnKeyDone;
        _textView.internalTextView.delegate = self;
        _textView.delegate = self;
    }
    return _textView;
}

- (UIPanGestureRecognizer *)textPanRecognizer {
    if (!_textPanRecognizer) {
        _textPanRecognizer = [[UIPanGestureRecognizer alloc] init];
        [_textPanRecognizer addTarget:self action:@selector(onTextPan:)];
    }
    return _textPanRecognizer;
}

- (NSDictionary *)watermarkAttributes {
    return @{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.5],
        NSFontAttributeName: [UIFont fontWithName:@"ProximaNovaSoft-Bold" size:24.0],
    };
}

- (UILabel *)watermarkLabel {
    if (!_watermarkLabel) {
        _watermarkLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        
        _watermarkLabel.attributedText =
        [[NSAttributedString alloc] initWithString:@"BIF" attributes:self.watermarkAttributes];
        
        [_watermarkLabel sizeToFit];
        UIEdgeInsets safetyInsets = UIEdgeInsetsMake(0.0, 0.0, -4.0, -4.0);
        _watermarkLabel.frame = UIEdgeInsetsInsetRect(_watermarkLabel.frame, safetyInsets);
    }
    return _watermarkLabel;
}

- (UILabel *)textHintLabel {
    if (!_textHintLabel) {
        _textHintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textHintLabel.font = [UIFont fontWithName:@"ProximaNovaSoft-Medium" size:14.0];
        _textHintLabel.textAlignment = NSTextAlignmentCenter;
        _textHintLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _textHintLabel.text = @"Drag text to move";
        
        [_textHintLabel sizeToFit];
    }
    return _textHintLabel;
}

- (UIView *)bottomBar {
    if (!_bottomBar) {
        _bottomBar = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return _bottomBar;
}

- (UITapGestureRecognizer *)rangePickerTapRecognizer {
    if (!_rangePickerTapRecognizer) {
        _rangePickerTapRecognizer = [[UITapGestureRecognizer alloc] init];
        [_rangePickerTapRecognizer addTarget:self action:@selector(onRangePickerTapped:)];
    }
    return _rangePickerTapRecognizer;
}

- (UISlider *)speedSlider {
    if (!_speedSlider) {
        _speedSlider = [[UISlider alloc] initWithFrame:CGRectZero];
        [_speedSlider setThumbImage:[UIImage imageNamed:@"sliderHandle"] forState:UIControlStateNormal];
        [_speedSlider addTarget:self
                         action:@selector(onSpeedSliderChanged)
               forControlEvents:UIControlEventValueChanged];
    }
    return _speedSlider;
}

- (BGTextButton *)repeatButton {
    if (!_repeatButton) {
        _repeatButton = [[BGTextButton alloc] initWithFrame:CGRectZero];
        [_repeatButton addTarget:self
                             action:@selector(onLoopModeChanged)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _repeatButton;
}

- (BGTextButton *)textButton {
    if (!_textButton) {
        _textButton = [[BGTextButton alloc] initWithFrame:CGRectZero];
        [_textButton setImageNamed:@"textGlyph"];
        [_textButton setTitle:@"Text"];
        [_textButton addTarget:self
                        action:@selector(onTextButtonTapped)
              forControlEvents:UIControlEventTouchUpInside];
    }
    return _textButton;
}

- (CGFloat)framesPerSecondForSliderValue:(CGFloat)sliderValue {
    return kBGMinimumFPS + (kBGMaximumFPS - kBGMinimumFPS) * sliderValue;
}

- (CGFloat)sliderValueForFramesPerSecond:(CGFloat)framesPerSecond {
    return (framesPerSecond - kBGMinimumFPS) / (kBGMaximumFPS - kBGMinimumFPS);
}

- (void)onSpeedSliderChanged {
    CGFloat framesPerSecond = [self framesPerSecondForSliderValue:self.speedSlider.value];
    self.burstGroup.framesPerSecond = framesPerSecond;
    self.previewView.framesPerSecond = framesPerSecond;
}

- (void)onLoopModeChanged {
    LoopMode newLoopMode;
    
    switch (self.burstGroup.loopMode) {
        case LoopModeLoop:
            newLoopMode = LoopModeReverse;
            break;
            
        case LoopModeReverse:
            newLoopMode = LoopModeLoop;
            break;
    }
    
    self.burstGroup.loopMode = newLoopMode;
    self.previewView.loopMode = newLoopMode;
    
    [self updateRepeatButtonForLoopMode:newLoopMode];
}

- (void)updateRepeatButtonForLoopMode:(LoopMode)loopMode {
    switch (loopMode) {
        case LoopModeLoop:
            [self.repeatButton setImageNamed:@"loopGlyph"];
            [self.repeatButton setTitle:@"Loop"];
            break;
            
        case LoopModeReverse:
            [self.repeatButton setImageNamed:@"reverseGlyph"];
            [self.repeatButton setTitle:@"Reverse"];
            break;
    }
}

- (void)onPreviewViewTapped {
    [self enterTextMode];
}

- (void)onTextButtonTapped {
    [self enterTextMode];
}

- (void)enterTextMode {
    self.showingText = YES;
    [self updateTextVisibility];
    [self.textView becomeFirstResponder];
}

- (void)updateTextVisibility {
    self.textView.hidden = !self.showingText;
}

- (void)onTextPan:(UIPanGestureRecognizer *)recognizer {
    static CGFloat relativeY;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            CGFloat locationInTextView = [recognizer locationInView:self.textView].y;
            relativeY = locationInTextView - self.textView.bounds.size.height / 2.0;
        } break;
            
        case UIGestureRecognizerStateChanged: {
            CGFloat absoluteY = [recognizer locationInView:self.previewView].y;
            CGFloat adjustedY = absoluteY - relativeY;
            CGFloat normalizedY = adjustedY / self.previewView.bounds.size.height;
            [self updateTextPositionWithDesiredPosition:normalizedY animated:YES];
        } break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            //
        } break;
            
        default:
            break;
    }
}

- (void)updateTextPositionWithDesiredPosition:(CGFloat)textPosition animated:(BOOL)animated {
    textPosition = MAX(MIN(textPosition, self.textView.maxPosition), self.textView.minPosition);
    
    CGPoint center = self.textView.center;
    center.y = self.previewView.bounds.size.height * textPosition;
    self.textView.center = center;
    
    void(^watermarkPositionBlock)(void) = ^{
        CGRect watermarkRect = self.watermarkLabel.frame;
        watermarkRect.origin.x = 10.0;
        if (self.textView.center.y > self.previewView.bounds.size.height / 2.0) {
            watermarkRect.origin.y = 10.0;
        } else {
            watermarkRect.origin.y = self.previewView.bounds.size.height - watermarkRect.size.height - 7.0;
        }
        self.watermarkLabel.frame = watermarkRect;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.75
                              delay:0.0
             usingSpringWithDamping:0.85
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:watermarkPositionBlock
                         completion:nil];
    } else {
        watermarkPositionBlock();
    }
    
    self.burstGroup.textPosition = textPosition;
}


#pragma mark -
#pragma mark Button Listeners

- (void)onBackButtonTapped {
    [self.delegate burstPreviewViewControllerWantsDismissal:self];
}

- (void)onShareButtonTapped {
    self.previewView.animated = NO;

    NSArray *photos = self.previewView.allPhotosInRangeWithLoopModeApplied;
    
    CGRect textRect = [self.previewView convertRect:self.textView.internalTextView.frame fromView:self.textView];
    textRect.origin.x /= self.previewView.frame.size.width;
    textRect.origin.y /= self.previewView.frame.size.height;
    textRect.size.width /= self.previewView.frame.size.width;
    textRect.size.height /= self.previewView.frame.size.height;
    
    BGTextElement *textElement = [[BGTextElement alloc] init];
    textElement.text = self.burstGroup.text;
    textElement.textAttributes = self.textAttributes;
    textElement.textRect = textRect;
    
    CGRect watermarkRect = self.watermarkLabel.frame;
    watermarkRect.origin.x /= self.previewView.frame.size.width;
    watermarkRect.origin.y /= self.previewView.frame.size.height;
    watermarkRect.size.width /= self.previewView.frame.size.width;
    watermarkRect.size.height /= self.previewView.frame.size.height;
    
    BGTextElement *watermarkElement = [[BGTextElement alloc] init];
    watermarkElement.text = self.watermarkLabel.text;
    watermarkElement.textAttributes = self.watermarkAttributes;
    watermarkElement.textRect = watermarkRect;
    
    NSArray *textElements = @[textElement, watermarkElement];
    
    BGFinalizedBurst *finalizedBurst =
    [[BGFinalizedBurst alloc] initWithPhotos:photos
                                    cropRect:self.previewView.cropInfo
                                  outputSize:kBGOutputSize
                               frameDuration:(1.0 / self.burstGroup.framesPerSecond)
                                textElements:textElements];

    BGShareViewController *shareVC = [[BGShareViewController alloc] initWithBurstGroup:self.burstGroup finalizedBurst:finalizedBurst];
//    self.shareTransition = [[BGShareTransition alloc] init];
//    shareVC.modalPresentationStyle = UIModalPresentationCustom;
//    shareVC.transitioningDelegate = self.shareTransition;
    [self presentViewController:shareVC animated:YES completion:nil];
    shareVC.delegate = self;
}

- (void)onRangePickerTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.delegate burstPreviewViewControllerWantsDismissal:self];
    }
}


#pragma mark -
#pragma mark BGBurstPreviewViewDelegate

- (void)burstPreviewView:(BGBurstPreviewView *)previewView didShowPhoto:(BGBurstPhoto *)photo {
    self.rangePicker.currentPhoto = photo;
}

- (void)burstPreviewView:(BGBurstPreviewView *)previewView didChangeCropInfo:(CGRect)cropInfo {
    self.burstGroup.cropInfo = cropInfo;
}


#pragma mark -
#pragma mark BGTextViewDelegate

- (void)textViewDidChangeSize:(BGTextView *)textView {
    [self updateTextPositionWithDesiredPosition:self.burstGroup.textPosition animated:YES];
}


#pragma mark -
#pragma mark UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self.containerView setScrollEnabled:YES];
}

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    textView.text = [textView.text stringByReplacingCharactersInRange:range withString:[text uppercaseString]];
    [self textViewDidChange:textView];
    return NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.burstGroup.text = textView.text;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (!textView.hasText) {
        self.showingText = NO;
        [self updateTextVisibility];
    }
    [self.containerView setScrollEnabled:NO];
}


#pragma mark -
#pragma mark Keyboard

- (void)onKeyboardWillChangeFrame:(NSNotification *)notification {
    [CATransaction commit];

    [UIView setAnimationsEnabled:NO];
    CGRect oldFrame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    [self updateTextHintLabelPositionWithKeyboardTopY:oldFrame.origin.y];
    [UIView setAnimationsEnabled:YES];
    
    CGRect newFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] floatValue];
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [UIView setAnimationCurve:animationCurve];
        
        [self updateTextHintLabelPositionWithKeyboardTopY:newFrame.origin.y];
        
        BOOL isDismissing = ABS(newFrame.origin.y - self.view.bounds.size.height) < 10.0;
        self.textHintLabel.alpha = isDismissing ? 0.0 : 1.0;
        
        CGFloat newContainerY = isDismissing ? 0.0 : -(self.topBar.bounds.size.height - kPreviewPadding);
        CGPoint containerCenter = self.containerView.center;
        containerCenter.y = newContainerY + self.containerView.bounds.size.height / 2.0;
        self.containerView.center = containerCenter;
        
        [self display:isDismissing includeRangePicker:YES];
    }];
}


#pragma mark -
#pragma mark Animations

- (void)display:(BOOL)display {
    [self display:display includeRangePicker:NO];
}

- (void)display:(BOOL)display includeRangePicker:(BOOL)includeRangePicker {
    CGFloat barAlpha = display ? 1.0 : 0.0;
    self.topBar.alpha = barAlpha;
    self.bottomBar.alpha = barAlpha;
    
    CGFloat barScale = display ? 1.0 : 0.1;
    CGAffineTransform barTransform = CGAffineTransformMakeScale(barScale, barScale);
    self.backButton.transform = barTransform;
    self.shareButton.transform = barTransform;
    self.repeatButton.transform = barTransform;
    self.textButton.transform = barTransform;
    self.speedSlider.transform = barTransform;
    
    if (includeRangePicker) {
        self.rangePicker.alpha = barAlpha;
        
        CGFloat rangePickerScale = display ? 1.0 : 0.8;
        self.rangePicker.transform = CGAffineTransformMakeScale(rangePickerScale, rangePickerScale);
    }
}


#pragma mark -
#pragma mark BGBurstGroupRangePickerDelegate

- (void)burstGroupRangePickerDidBeginAdjustingRange:(BGBurstGroupRangePicker *)picker {
    self.previewView.animated = NO;
}

- (void)burstGroupRangePickerDidUpdateRange:(BGBurstGroupRangePicker *)picker frameIndex:(NSUInteger)frameIndex {
    [self updatePhotoRange];
}

- (void)burstGroupRangePickerDidEndAdjustingRange:(BGBurstGroupRangePicker *)picker {
    self.previewView.animated = YES;
}

- (void)updatePhotoRange {
    self.previewView.range = self.burstGroup.range;
}


#pragma mark -
#pragma mark BGShareViewControllerDelegate

- (void)shareViewControllerWantsDismissal:(BGShareViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark UIScrollViewDelegae

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    scrollView.contentOffset = CGPointMake(0.0, 0.0);
}


#pragma mark -
#pragma mark Dismiss Keybord Button

- (void)updateTextHintLabelPositionWithKeyboardTopY:(CGFloat)keyboardTopY {
    CGPoint textHintButtonCenter = self.textHintLabel.center;
    textHintButtonCenter.x = self.containerView.bounds.size.width / 2;
    textHintButtonCenter.y = keyboardTopY - (keyboardTopY - (kPreviewPadding + [self previewSize])) / 2;
    textHintButtonCenter.y -= self.containerView.contentOffset.y;
    self.textHintLabel.center = textHintButtonCenter;
}


#pragma mark -
#pragma mark BGEditTransitionPreviewController

- (CGRect)rectForRangePickerView {
    CGFloat rangePickerY = [self topBarHeight] +  [self previewSize] + [self verticalSpacingForBottomView];
    CGFloat rangePickerWidth = self.view.bounds.size.width - 2 * kBGLargePadding;
    return CGRectMake(kBGLargePadding, rangePickerY, rangePickerWidth, kRangePickerHeight);
}

- (BGBurstGroupRangePicker *)stealRangePickerView {
    BGBurstGroupRangePicker *rangePicker = self.rangePicker;
    rangePicker.delegate = nil;
    [rangePicker removeGestureRecognizer:self.rangePickerTapRecognizer];
    self.rangePicker = nil;
    return rangePicker;
}

- (void)prepareRangePickerView:(BGBurstGroupRangePicker *)rangePickerView {
    self.rangePicker = rangePickerView;
    self.rangePicker.burstGroup = self.burstGroup;
    self.rangePicker.delegate = self;
}

- (void)placeRangePickerView:(BGBurstGroupRangePicker *)rangePickerView {
    [self.rangePicker addGestureRecognizer:self.rangePickerTapRecognizer];
    [self.view addSubview:self.rangePicker];
}

- (UIView *)mediaView {
    return self.previewView;
}

@end
