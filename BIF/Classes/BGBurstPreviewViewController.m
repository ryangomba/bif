// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstPreviewViewController.h"

#import "BGBurstGroupRangePicker.h"
#import "BGBurstPreviewView.h"
#import "BGGIFMaker.h"
#import "BGProgressHUD.h"
#import "BGBurstInfo.h"
#import "BGDatabase.h"
#import "BIFHelpers.h"
#import "BGTextView.h"
#import "BGShareViewController.h"
#import "BGTextButton.h"
#import "BGShareTransition.h"

static CGFloat const kButtonSize = 56.0;
static CGFloat const kRangePickerHeight = 60.0;
static CGFloat const kPreviewPadding = 10.0;

@interface BGBurstPreviewViewController ()<BGBurstGroupRangePickerDelegate, UITextViewDelegate, BGTextViewDelegate, BGBurstPreviewViewDelegate, BGShareViewControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) BGBurstGroup *burstGroup;

@property (nonatomic, strong) UIScrollView *containerView;

@property (nonatomic, strong, readwrite) BGBurstPreviewView *previewView;

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) BGTextButton *backButton;
@property (nonatomic, strong) BGTextButton *shareButton;

@property (nonatomic, strong) BGTextView *textView;
@property (nonatomic, strong) UIButton *dismissKeyboardButton;
@property (nonatomic, strong) UIPanGestureRecognizer *textPanRecognizer;

@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) BGBurstGroupRangePicker *rangePicker;
@property (nonatomic, strong) UITapGestureRecognizer *rangePickerTapRecognizer;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) BGTextButton *repeatButton;
@property (nonatomic, strong) BGTextButton *textButton;

@property (nonatomic, strong) BGProgressHUD *progressHUD;

@property (nonatomic, assign) CGFloat currentKeyboardTopY;

@property (nonatomic, assign) BOOL showingText;

@property (nonatomic, strong) BGShareTransition *shareTransition;

@end


@implementation BGBurstPreviewViewController

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.burstGroup = burstGroup;
        
        self.speedSlider.value = [self sliderValueForFramesPerSecond:self.burstGroup.burstInfo.framesPerSecond];
        self.previewView.framesPerSecond = self.burstGroup.burstInfo.framesPerSecond;
        
        [self updateRepeatButtonForLoopMode:self.burstGroup.burstInfo.loopMode];
        self.previewView.loopMode = self.burstGroup.burstInfo.loopMode;
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
    self.previewView.assets = self.burstGroup.photos;
    self.previewView.cropInfo = self.burstGroup.burstInfo.cropInfo;
    [self.containerView addSubview:self.previewView];
    
    self.textView.frame = self.previewView.bounds;
    [self.previewView addSubview:self.textView];
    
    CGFloat dismissKeyboardButtonWidth = 44.0; // HACK hardcoded
    CGFloat dismissKeyboardButtonHeight = 44.0; // HACK hardcoded
    CGFloat dismissButtonX = (self.view.bounds.size.width - dismissKeyboardButtonWidth) / 2;
    CGFloat dismissButtonY = self.view.bounds.size.height - dismissKeyboardButtonHeight;
    CGRect dismissButtonRect = CGRectMake(dismissButtonX, dismissButtonY, dismissKeyboardButtonWidth, dismissKeyboardButtonHeight);
    self.dismissKeyboardButton.frame = dismissButtonRect;
    [self.view addSubview:self.dismissKeyboardButton];
    self.dismissKeyboardButton.alpha = 0.0;

    // bottom bar
    
    self.bottomBar.frame = CGRectMake(0.0, CGRectGetMaxY(self.previewView.frame), self.view.bounds.size.width, [self bottomBarHeight]);
    [self.view addSubview:self.bottomBar];
    
    [self setUpBottomBar];
    
    // setup
    
    [self updatePhotoRange];
    
    self.textView.internalTextView.text = self.burstGroup.burstInfo.text;
    self.showingText = self.burstGroup.burstInfo.text.length > 0;
    [self updateTextPositionWithDesiredPosition:self.burstGroup.burstInfo.textPosition ?: 0.5];
    [self updateTextVisibility];
    
    self.previewView.animated = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [BGDatabase saveBurstInfo:self.burstGroup.burstInfo];
    
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
    
    CGFloat sliderPadding = 32.0; // HACK hardcoded
    CGFloat speedSliderY = buttonY;
    CGFloat speedSliderX = CGRectGetMaxX(textButtonRect) + sliderPadding;
    CGFloat speedSliderWidth = self.view.bounds.size.width - (textButtonRect.size.width + sliderPadding + buttonPadding) * 2;
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

- (BGTextView *)textView {
    if (!_textView) {
        _textView = [[BGTextView alloc] initWithFrame:CGRectZero];
        
        _textView.internalTextView.attributedText =
        [[NSAttributedString alloc] initWithString:@"placeholder" attributes:self.textAttributes];
        
        [_textView addGestureRecognizer:self.textPanRecognizer];
        
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

- (UIButton *)dismissKeyboardButton {
    if (!_dismissKeyboardButton) {
        _dismissKeyboardButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_dismissKeyboardButton setImage:[UIImage imageNamed:@"dismissKeyboardGlyph"] forState:UIControlStateNormal];
        _dismissKeyboardButton.imageView.contentMode = UIViewContentModeCenter;
        [_dismissKeyboardButton addTarget:self
                                   action:@selector(onDismissKeyboardButtonTapped)
                         forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissKeyboardButton;
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


#define kMinimumFPS 4.0
#define kMaximumFPS 20.0

- (CGFloat)framesPerSecondForSliderValue:(CGFloat)sliderValue {
    return kMinimumFPS + (kMaximumFPS - kMinimumFPS) * sliderValue;
}

- (CGFloat)sliderValueForFramesPerSecond:(CGFloat)framesPerSecond {
    return (framesPerSecond - kMinimumFPS) / (kMaximumFPS - kMinimumFPS);
}

- (void)onSpeedSliderChanged {
    CGFloat framesPerSecond = [self framesPerSecondForSliderValue:self.speedSlider.value];
    self.burstGroup.burstInfo.framesPerSecond = framesPerSecond;
    self.previewView.framesPerSecond = framesPerSecond;
}

- (void)onLoopModeChanged {
    LoopMode newLoopMode;
    
    switch (self.burstGroup.burstInfo.loopMode) {
        case LoopModeLoop:
            newLoopMode = LoopModeReverse;
            break;
            
        case LoopModeReverse:
            newLoopMode = LoopModeLoop;
            break;
    }
    
    self.burstGroup.burstInfo.loopMode = newLoopMode;
    self.previewView.loopMode = newLoopMode;
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
            [self updateTextPositionWithDesiredPosition:normalizedY];
        } break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            //
        } break;
            
        default:
            break;
    }
}

- (void)updateTextPositionWithDesiredPosition:(CGFloat)textPosition {
    textPosition = MAX(MIN(textPosition, self.textView.maxPosition), self.textView.minPosition);
    
    CGPoint center = self.textView.center;
    center.y = self.previewView.bounds.size.height * textPosition;
    self.textView.center = center;
    
    self.burstGroup.burstInfo.textPosition = textPosition;
}

- (void)onDismissKeyboardButtonTapped {
    [self.textView resignFirstResponder];
}

- (NSDictionary *)textAttributes {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeZero;
    shadow.shadowBlurRadius = 5.0;
    
    return @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:48.0],
        NSParagraphStyleAttributeName: paragraphStyle,
        NSStrokeColorAttributeName:[UIColor blackColor],
        NSStrokeWidthAttributeName: @(-5.0),
//        NSShadowAttributeName: shadow,
    };
}


#pragma mark -
#pragma mark Button Listeners

- (void)onBackButtonTapped {
    [self.delegate burstPreviewViewControllerWantsDismissal:self];
}

- (void)onShareButtonTapped {
    self.progressHUD = [[BGProgressHUD alloc] init];
    self.progressHUD.center = self.view.center;
    self.progressHUD.text = @"Generating GIF";
    [self.view addSubview:self.progressHUD];
    self.view.userInteractionEnabled = NO;
    
    // HACK
    CGFloat outputSize = 320.0;
    CGRect textRect = [self.previewView convertRect:self.textView.internalTextView.frame fromView:self.textView];
    textRect.origin.x /= self.previewView.frame.size.width;
    textRect.origin.y /= self.previewView.frame.size.height;
    textRect.size.width /= self.previewView.frame.size.width;
    textRect.size.height /= self.previewView.frame.size.height;
    
    NSArray *images = self.previewView.allImagesInRangeWithLoopModeApplied;
    CGSize imageSize = [images.firstObject size];
    
    CGRect cropInfo = self.previewView.cropInfo;
    CGRect cropRect = CGRectZero;
    cropRect.origin.x = imageSize.width * cropInfo.origin.x;
    cropRect.origin.y = imageSize.height * cropInfo.origin.y;
    cropRect.size.width = imageSize.width * cropInfo.size.width;
    cropRect.size.height = imageSize.height * cropInfo.size.height;
    
    [BGGIFMaker makeGIFWithImages:images
                         cropRect:cropRect
                       outputSize:outputSize
                    frameDuration:(1.0 / self.burstGroup.burstInfo.framesPerSecond)
                             text:self.burstGroup.burstInfo.text
                         textRect:textRect
                   textAttributes:self.textAttributes
                       completion:^(NSString *filePath)
    {
        [self.progressHUD removeFromSuperview];
        self.view.userInteractionEnabled = YES;
        
        BGShareViewController *shareVC = [[BGShareViewController alloc] initWithBurstGroup:self.burstGroup filePath:filePath];
        self.shareTransition = [[BGShareTransition alloc] init];
        shareVC.transitioningDelegate = self.shareTransition;
        [self presentViewController:shareVC animated:YES completion:nil];
        shareVC.delegate = self;
    }];
}

- (void)onRangePickerTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.delegate burstPreviewViewControllerWantsDismissal:self];
    }
}


#pragma mark -
#pragma mark BGBurstPreviewViewDelegate

- (void)burstPreviewView:(BGBurstPreviewView *)previewView didChangeCropInfo:(CGRect)cropInfo {
    self.burstGroup.burstInfo.cropInfo = cropInfo;
}


#pragma mark -
#pragma mark BGTextViewDelegate

- (void)textViewDidChangeSize:(BGTextView *)textView {
    [self updateTextPositionWithDesiredPosition:self.burstGroup.burstInfo.textPosition];
}


#pragma mark -
#pragma mark UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self.containerView setScrollEnabled:YES];
}

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    
    textView.text = [textView.text stringByReplacingCharactersInRange:range withString:[text uppercaseString]];
    [self textViewDidChange:textView];
    return NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.burstGroup.burstInfo.text = textView.text;
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
    CGRect newFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] floatValue];
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    self.currentKeyboardTopY = newFrame.origin.y;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [UIView setAnimationCurve:animationCurve];
        
        [self updateDismissKeyboardButtonPosition];
        
        BOOL isDismissing = ABS(newFrame.origin.y - self.view.bounds.size.height) < 10.0;
        self.dismissKeyboardButton.alpha = isDismissing ? 0.0 : 1.0;
        
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
    self.previewView.staticIndex = frameIndex;
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

- (void)updateDismissKeyboardButtonPosition {
    CGPoint dismissButtonCenter = self.dismissKeyboardButton.center;
    dismissButtonCenter.y = self.currentKeyboardTopY - (self.currentKeyboardTopY - (kPreviewPadding + [self previewSize])) / 2;
    dismissButtonCenter.y -= self.containerView.contentOffset.y;
    self.dismissKeyboardButton.center = dismissButtonCenter;
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
    [rangePicker setEditable:NO animated:NO];
    [rangePicker removeGestureRecognizer:self.rangePickerTapRecognizer];
    self.rangePicker = nil;
    return rangePicker;
}

- (void)setRangePickerView:(BGBurstGroupRangePicker *)rangePickerView {
    self.rangePicker = rangePickerView;
    [self.rangePicker setEditable:YES animated:YES];
    self.rangePicker.delegate = self;
    [self.rangePicker addGestureRecognizer:self.rangePickerTapRecognizer];
    [self.view addSubview:self.rangePicker];
}

- (UIView *)mediaView {
    return self.previewView;
}

@end
