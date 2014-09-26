// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGShareCell.h"

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
        
        _textLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        _textLabel.layer.borderWidth = 1.0;
    }
    return _textLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 36.0, 36.0)];
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
    self.imageView.image = [UIImage imageNamed:imageName];
}

- (void)setShareState:(BGShareCellState)shareState {
    _shareState = shareState;
    
    switch (shareState) {
        case BGShareCellStateNormal:
            self.textLabel.text = self.defaultTitle;
            [self.spinner removeFromSuperview];
            [self.contentView addSubview:self.imageView];
            break;
            
        case BGShareCellStateSharing:
            self.textLabel.text = self.workingTitle;
            [self.imageView removeFromSuperview];
            [self.contentView addSubview:self.spinner];
            break;
            
        case BGShareCellStateShared:
            self.textLabel.text = self.successTitle;
            [self.spinner removeFromSuperview];
            [self.contentView addSubview:self.imageView];
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = self.contentView.bounds;
    self.textLabel.layer.cornerRadius = self.contentView.bounds.size.height / 2.0;
    
    CGPoint accessoryCenter = CGPointMake(30.0, self.contentView.bounds.size.height / 2.0);
    self.imageView.center = accessoryCenter;
    self.spinner.center = accessoryCenter;
}

@end
