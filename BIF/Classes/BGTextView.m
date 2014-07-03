//
//  BGTextView.m
//  BIF
//
//  Created by Ryan Gomba on 7/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGTextView.h"

@interface BGTextView ()

@property (nonatomic, readwrite) UITextView *internalTextView;

@end

@implementation BGTextView

- (void)dealloc {
    [_internalTextView removeObserver:self forKeyPath:@"contentSize"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.internalTextView];
    }
    return self;
}

- (BOOL)becomeFirstResponder {
    return [self.internalTextView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.internalTextView resignFirstResponder];
}

- (BOOL)isFirstResponder {
    return [self.internalTextView isFirstResponder];
}

- (UITextView *)internalTextView {
    if (!_internalTextView) {
        _internalTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        _internalTextView.backgroundColor = [UIColor clearColor];
        [_internalTextView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
    return _internalTextView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setNeedsLayout];
    
    [self.delegate textViewDidChangeSize:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat textViewX = 0.0;
    CGFloat textViewWidth = self.bounds.size.width;
    CGFloat textViewHeight = self.internalTextView.contentSize.height;
    CGFloat textViewY = (self.bounds.size.height - textViewHeight) / 2.0;
    CGRect textViewRect = CGRectMake(textViewX, textViewY, textViewWidth, textViewHeight);
    self.internalTextView.frame = textViewRect;
    
    [self.internalTextView setContentOffset:CGPointZero animated:NO];
}

- (CGFloat)minPosition {
    CGFloat neededY = self.internalTextView.contentSize.height / 2.0;
    return neededY / self.bounds.size.height;
}

- (CGFloat)maxPosition {
    return 1.0 - self.minPosition;
}

@end
