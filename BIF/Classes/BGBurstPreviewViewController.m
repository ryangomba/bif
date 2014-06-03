//
//  CHBurstGroupPreviewViewController.m
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGBurstPreviewViewController.h"

#import "BGBurstGroupRangePicker.h"
#import "BGBurstPreviewView.h"
#import "BGGIFMaker.h"
#import "BGFileUploader.h"
#import "BGProgressHUD.h"
#import "BGBurstInfo.h"
#import "BGDatabase.h"

@interface BGBurstPreviewViewController ()<BGBurstGroupRangePickerDelegate>

@property (nonatomic, strong) BGBurstGroup *burstGroup;

@property (nonatomic, strong) BGBurstPreviewView *previewView;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) BGBurstGroupRangePicker *rangePicker;
@property (nonatomic, strong) BGProgressHUD *progressHUD;

@end


@implementation BGBurstPreviewViewController

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.burstGroup = burstGroup;
        
        self.speedSlider.value = [self sliderValueForFramesPerSecond:self.burstGroup.burstInfo.framesPerSecond];
        self.previewView.framesPerSecond = self.burstGroup.burstInfo.framesPerSecond;
        
        self.navigationItem.title = @"Burst";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onDoneButtonTapped)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    self.previewView.frame = CGRectMake(20.0, 80.0, 280.0, 280.0);
    self.previewView.assets = self.burstGroup.photos;
    [self.view addSubview:self.previewView];
    
    self.speedSlider.frame = CGRectMake(20.0, 370.0, 280.0, 20.0);
    [self.view addSubview:self.speedSlider];
    
    self.rangePicker.frame = CGRectMake(20.0, 400.0, 280.0, 60.0);
    self.rangePicker.burstGroup = self.burstGroup;
    [self.view addSubview:self.rangePicker];
    
    [self updatePhotoRange];
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
    }
    return _previewView;
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

- (void)onDoneButtonTapped {
    self.progressHUD = [[BGProgressHUD alloc] init];
    self.progressHUD.center = self.view.center;
    self.progressHUD.text = @"Generating GIF";
    [self.view addSubview:self.progressHUD];
    self.view.userInteractionEnabled = NO;
    
    [BGGIFMaker makeGIFWithImages:self.previewView.allImagesInRange
                       outputSize:320.0
                    frameDuration:(1.0 / self.burstGroup.burstInfo.framesPerSecond)
                       completion:^(NSString *filePath)
    {
        self.progressHUD.text = @"Uploading GIF";
        [BGFileUploader uploadFileAtPath:filePath completion:^(NSURL *url, NSError *error) {
            [self.progressHUD removeFromSuperview];
            self.view.userInteractionEnabled = YES;
            
            if (url) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.URL = url;
                
                [[[UIAlertView alloc] initWithTitle:@"GIF Created!"
                                            message:@"A URL has been copied to your clipboard."
                                           delegate:nil
                                  cancelButtonTitle:@"Sweet"
                                  otherButtonTitles:nil] show];
                
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:error.localizedDescription
                                           delegate:nil
                                  cancelButtonTitle:@"Dismiss"
                                  otherButtonTitles:nil] show];
            }
        }];
    }];
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
