@import UIKit;

#import "BGLoadingInfoView.h"

static CGFloat const kSpinnerPadding = 12.0;

@interface BGLoadingInfoView ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *label;

@end

@implementation BGLoadingInfoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.spinner];
        [self addSubview:self.label];
    }
    return self;
}

- (UIActivityIndicatorView *)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_spinner startAnimating];
    }
    return _spinner;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont fontWithName:@"ProximaNovaSoft-Medium" size:18.0];
        _label.textColor = [UIColor whiteColor];
    }
    return _label;
}

- (NSString *)text {
    return self.label.text;
}

- (void)setText:(NSString *)text {
    self.label.text = text;
    [self.label sizeToFit];
    
    [self setNeedsLayout];
}

- (void)setBottomInset:(CGFloat)bottomInset {
    _bottomInset = bottomInset;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.label.bounds.size.width + self.spinner.bounds.size.width + kSpinnerPadding + 20.0; // dat weighting tho
    CGFloat contentX = (self.bounds.size.width - contentWidth) / 2;
    
    CGFloat spinnerY = (self.bounds.size.height - self.bottomInset - self.spinner.bounds.size.height) / 2;
    CGFloat spinnerCenterX = contentX + self.spinner.bounds.size.width / 2;
    CGFloat spinnerCenterY = spinnerY + self.spinner.bounds.size.height / 2;
    self.spinner.center = CGPointMake(spinnerCenterX, spinnerCenterY);
    
    CGFloat labelX = CGRectGetMaxX(self.spinner.frame) + kSpinnerPadding;
    CGFloat labelY = (self.bounds.size.height - self.bottomInset - self.label.bounds.size.height) / 2;
    CGFloat labelCenterX = labelX + self.label.bounds.size.width / 2;
    CGFloat labelCenterY = labelY + self.label.bounds.size.height / 2;
    self.label.center = CGPointMake(labelCenterX, labelCenterY);
}

@end
