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

@interface BGBurstPreviewViewController ()<BGBurstGroupRangePickerDelegate, UITextViewDelegate, BGTextViewDelegate>

@property (nonatomic, strong) BGBurstGroup *burstGroup;

@property (nonatomic, strong) BGBurstPreviewView *previewView;

@property (nonatomic, strong) BGTextView *textView;
@property (nonatomic, strong) UIButton *dismissKeyboardButton;
@property (nonatomic, strong) UIPanGestureRecognizer *textPanRecognizer;

@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) BGBurstGroupRangePicker *rangePicker;
@property (nonatomic, strong) UISegmentedControl *loopModeControl;
@property (nonatomic, strong) UIButton *textButton;

@property (nonatomic, strong) BGProgressHUD *progressHUD;

@property (nonatomic, assign) BOOL showingText;

@end


@implementation BGBurstPreviewViewController

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.burstGroup = burstGroup;
        
        self.speedSlider.value = [self sliderValueForFramesPerSecond:self.burstGroup.burstInfo.framesPerSecond];
        self.previewView.framesPerSecond = self.burstGroup.burstInfo.framesPerSecond;
        
        self.loopModeControl.selectedSegmentIndex = self.burstGroup.burstInfo.loopMode;
        self.previewView.loopMode = self.burstGroup.burstInfo.loopMode;
        
        self.navigationItem.title = @"Edit";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(onDoneButtonTapped)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat elementX = kBGDefaultPadding;
    CGFloat elementWidth = self.view.bounds.size.width - 2 * kBGDefaultPadding;
    
    CGFloat previewSize = self.view.bounds.size.width;
    self.previewView.frame = CGRectMake(0.0, 0.0, previewSize, previewSize);
    self.previewView.assets = self.burstGroup.photos;
    [self.view addSubview:self.previewView];
    
    self.textView.frame = self.previewView.frame;
    [self.view addSubview:self.textView];
    
    CGFloat textButtonSize = 44.0;
    CGFloat textButtonX = CGRectGetMaxX(self.previewView.frame) - kBGDefaultPadding - textButtonSize;
    CGFloat textButtonY = CGRectGetMaxY(self.previewView.frame) - kBGDefaultPadding - textButtonSize;
    self.textButton.frame = CGRectMake(textButtonX, textButtonY, textButtonSize, textButtonSize);
    [self.view addSubview:self.textButton];
    
    self.dismissKeyboardButton.frame = self.textButton.frame;
    [self.view addSubview:self.dismissKeyboardButton];
    self.dismissKeyboardButton.hidden = YES;

    CGFloat rangePickerY = CGRectGetMaxY(self.previewView.frame) + kBGDefaultPadding;
    self.rangePicker.frame = CGRectMake(elementX, rangePickerY, elementWidth, 60.0);
    self.rangePicker.burstGroup = self.burstGroup;
    [self.view addSubview:self.rangePicker];

    CGFloat loopModeControlY = CGRectGetMaxY(self.rangePicker.frame) + kBGDefaultPadding;
    self.loopModeControl.frame = CGRectMake(elementX, loopModeControlY, 100.0, 44.0);
    [self.view addSubview:self.loopModeControl];
    
    CGFloat speedSliderY = loopModeControlY;
    CGFloat speedSliderX = CGRectGetMaxX(self.loopModeControl.frame) + kBGDefaultPadding;
    CGFloat speedSliderWidth = elementWidth - self.loopModeControl.frame.size.width - kBGDefaultPadding;
    self.speedSlider.frame = CGRectMake(speedSliderX, speedSliderY, speedSliderWidth, 44.0);
    [self.view addSubview:self.speedSlider];
    
    [self updatePhotoRange];
    
    self.textView.internalTextView.text = self.burstGroup.burstInfo.text;
    self.showingText = self.burstGroup.burstInfo.text.length > 0;
    [self updateTextPositionWithDesiredPosition:self.burstGroup.burstInfo.textPosition ?: 0.5];
    [self updateTextVisibility];
    
    self.previewView.animated = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [BGDatabase saveBurstInfo:self.burstGroup.burstInfo];
}

- (BGBurstPreviewView *)previewView {
    if (!_previewView) {
        _previewView = [[BGBurstPreviewView alloc] initWithFrame:CGRectZero];
        _previewView.backgroundColor = [UIColor whiteColor];
        
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
        _dismissKeyboardButton.backgroundColor = [UIColor grayColor];
        [_dismissKeyboardButton setTitle:@"Dismiss" forState:UIControlStateNormal];
        [_dismissKeyboardButton addTarget:self
                                   action:@selector(onDismissKeyboardButtonTapped)
                         forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissKeyboardButton;
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

- (UISegmentedControl *)loopModeControl {
    if (!_loopModeControl) {
        _loopModeControl = [[UISegmentedControl alloc] initWithItems:@[@"Loop", @"Reverse"]];
        [_loopModeControl addTarget:self
                             action:@selector(onLoopModeChanged)
                   forControlEvents:UIControlEventValueChanged];
    }
    return _loopModeControl;
}

- (UIButton *)textButton {
    if (!_textButton) {
        _textButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _textButton.backgroundColor = [UIColor grayColor];
        [_textButton setTitle:@"T" forState:UIControlStateNormal];
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

- (BGBurstGroupRangePicker *)rangePicker {
    if (!_rangePicker) {
        _rangePicker = [[BGBurstGroupRangePicker alloc] initWithFrame:CGRectZero];
        _rangePicker.delegate = self;
    }
    return _rangePicker;
}

- (void)onSpeedSliderChanged {
    CGFloat framesPerSecond = [self framesPerSecondForSliderValue:self.speedSlider.value];
    self.burstGroup.burstInfo.framesPerSecond = framesPerSecond;
    self.previewView.framesPerSecond = framesPerSecond;
}

- (void)onLoopModeChanged {
    LoopMode loopMode = self.loopModeControl.selectedSegmentIndex;
    self.burstGroup.burstInfo.loopMode = loopMode;
    self.previewView.loopMode = loopMode;
}

- (void)onPreviewViewTapped {
    self.showingText = YES;
    [self updateTextVisibility];
    [self.textView becomeFirstResponder];
}

- (void)onTextButtonTapped {
    self.showingText = !self.showingText;
    
    [self updateTextVisibility];
    
    if (self.showingText && !self.textView.internalTextView.hasText) {
        [self.textView becomeFirstResponder];
    }
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

- (void)onDoneButtonTapped {
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
    
    [BGGIFMaker makeGIFWithImages:self.previewView.allImagesInRangeWithLoopModeApplied
                       outputSize:outputSize
                    frameDuration:(1.0 / self.burstGroup.burstInfo.framesPerSecond)
     text:self.burstGroup.burstInfo.text
                         textRect:textRect
                   textAttributes:self.textAttributes
                       completion:^(NSString *filePath)
    {
        [self.progressHUD removeFromSuperview];
        self.view.userInteractionEnabled = YES;
        
        BGShareViewController *shareVC =
        [[BGShareViewController alloc] initWithBurstGroup:self.burstGroup filePath:filePath];
        [self.navigationController pushViewController:shareVC animated:YES];
    }];
}


#pragma mark -
#pragma mark BGTextViewDelegate

- (void)textViewDidChangeSize:(BGTextView *)textView {
    [self updateTextPositionWithDesiredPosition:self.burstGroup.burstInfo.textPosition];
}


#pragma mark -
#pragma mark UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.dismissKeyboardButton.hidden = NO;
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
    self.dismissKeyboardButton.hidden = YES;
    
    if (!textView.hasText) {
        self.showingText = NO;
        [self updateTextVisibility];
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

@end
