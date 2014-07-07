// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGProgressHUD.h"

@interface BGProgressHUD ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end


@implementation BGProgressHUD

- (instancetype)init {
    if (self = [super initWithFrame:CGRectMake(0.0, 0.0, 240.0, 160.0)]) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.90];
        self.layer.cornerRadius = 3.0;
        
        self.textLabel.frame = CGRectMake(0.0, 0.0, 240.0, 80.0);
        [self addSubview:self.textLabel];
        
        self.spinner.center = CGPointMake(120.0, 100.0);
        [self addSubview:self.spinner];
    }
    return self;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.font = [UIFont systemFontOfSize:20.0];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
    }
    return _textLabel;
}

- (UIActivityIndicatorView *)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_spinner startAnimating];
    }
    return _spinner;
}

- (void)setText:(NSString *)text {
    _text = [text copy];
    
    self.textLabel.text = text;
}

@end
