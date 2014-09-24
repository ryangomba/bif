// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGTextButton.h"

static CGFloat const kImageViewSize = 36.0;
static CGFloat const kTitleLabelHeight = 20.0;

@implementation BGTextButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont fontWithName:@"ProximaNovaSoft-Medium" size:10.0];
    }
    return self;
}

- (void)setImageNamed:(NSString *)imageName {
    [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title {
    [self setTitle:title.uppercaseString forState:UIControlStateNormal];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat imageViewX = (self.bounds.size.width - kImageViewSize) / 2;
    CGFloat imageViewY = (self.bounds.size.height - kImageViewSize - kTitleLabelHeight) / 2;
    self.imageView.frame = CGRectMake(imageViewX, imageViewY, kImageViewSize, kImageViewSize);
    
    CGFloat titleLabelY = CGRectGetMaxY(self.imageView.frame);
    self.titleLabel.frame = CGRectMake(0.0, titleLabelY, self.bounds.size.width, kTitleLabelHeight);
}

@end
