// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupCell.h"

@interface BGBurstGroupCell ()

@property (nonatomic, strong, readwrite) BGBurstGroupView *burstGroupView;

@end


@implementation BGBurstGroupCell

- (instancetype)initWithFrame:(CGRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.burstGroupView = [[BGBurstGroupView alloc] initWithFrame:self.contentView.bounds];
        self.burstGroupView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.burstGroupView];
        
        self.burstGroupView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.burstGroupView.layer.shadowOpacity = 0.5;
        self.burstGroupView.layer.shadowOffset = CGSizeZero;
        self.burstGroupView.layer.shadowRadius = 1.0;
        self.burstGroupView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.burstGroupView.bounds].CGPath;
        
        self.burstGroupView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        self.burstGroupView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return self;
}

- (void)setBurstGroup:(BGBurstGroup *)burstGroup {
    if (burstGroup == _burstGroup) {
        return;
    }
    
    _burstGroup = burstGroup;

    self.burstGroupView.assets = burstGroup.photos;
}

- (BGBurstGroupView *)stealBurstGroupView {
    return self.burstGroupView;
}

- (void)returnBurstGroupView:(BGBurstGroupView *)burstGroupView {
    burstGroupView.frame = self.contentView.bounds;
    [self.contentView addSubview:self.burstGroupView];
}

- (void)prepareForReuse {
    self.burstGroupView.assets = nil;
}

@end
