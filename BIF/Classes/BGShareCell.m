// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGShareCell.h"

#import "BIFHelpers.h"

@interface BGShareCell ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, copy) NSString *defaultTitle;
@property (nonatomic, copy) NSString *workingTitle;
@property (nonatomic, copy) NSString *successTitle;

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

- (UIActivityIndicatorView *)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_spinner startAnimating];
    }
    return _spinner;
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
    UIColor *color;
    
    switch (shareState) {
        case BGShareCellStateNormal:
            text = self.defaultTitle;
            showSpinner = NO;
            color = [UIColor whiteColor];
            break;
            
        case BGShareCellStateSharing:
            text = self.workingTitle;
            showSpinner = YES;
            color = HEX_COLOR(0x72daff);
            break;
            
        case BGShareCellStateShared:
            text = self.successTitle;
            showSpinner = NO;
            color = HEX_COLOR(0x73ff7c);
            break;
    }
    
    self.textLabel.text = text;
    
    self.textLabel.textColor = color;
    self.imageView.tintColor = color;
    self.textLabel.layer.borderColor = color.CGColor;
    self.imageView.layer.borderColor = color.CGColor;
    
    if (showSpinner) {
        [self.imageView removeFromSuperview];
        [self.contentView addSubview:self.spinner];
    } else {
        [self.spinner removeFromSuperview];
        [self.contentView addSubview:self.imageView];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.defaultTitle.length > 0) {
        self.textLabel.frame = self.contentView.bounds;
        self.textLabel.layer.cornerRadius = self.contentView.bounds.size.height / 2.0;
        self.textLabel.hidden = NO;
        
        CGPoint accessoryCenter = CGPointMake(30.0, self.contentView.bounds.size.height / 2.0);
        self.imageView.frame = CGRectMake(0.0, 0.0, 36.0, 36.0);
        self.imageView.center = accessoryCenter;
        self.spinner.center = accessoryCenter;
        self.imageView.layer.borderWidth = 0.0;
        
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

@end
