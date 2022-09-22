@import UIKit;

#import "BGCollectionView.h"

@implementation BGCollectionView

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"contentSize"];
    [self removeObserver:self forKeyPath:@"contentInset"];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        // TODO simplify
        [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)setFooterView:(UIView *)footerView {
    if (footerView == _footerView) {
        return;
    }
    
    [_footerView removeFromSuperview];
    
    _footerView = footerView;
    
    [self addSubview:self.footerView];
    [self updateFooterViewPosition];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    [self updateFooterViewPosition];
}

- (void)updateFooterViewPosition {
    CGFloat footerViewY = self.contentInset.top + self.contentSize.height;
    CGFloat footerViewWidth = self.bounds.size.width;
    CGFloat footerViewHeight = self.footerView.bounds.size.height;
    self.footerView.frame = CGRectMake(0.0, footerViewY, footerViewWidth, footerViewHeight);
    
    UIEdgeInsets contentInset = self.contentInset;
    if (contentInset.bottom != footerViewHeight) {
        contentInset.bottom = footerViewHeight;
        self.contentInset = contentInset;
    }
}

@end
