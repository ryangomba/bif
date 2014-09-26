// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGShareCell.h"

@interface BGShareCell ()

@property (nonatomic, strong, readwrite) UILabel *textLabel;

@end

@implementation BGShareCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.textLabel];
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

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = self.contentView.bounds;
    self.textLabel.layer.cornerRadius = self.contentView.bounds.size.height / 2.0;
}

@end
