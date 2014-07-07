// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupCell.h"

#import "BGBurstGroupView.h"

@interface BGBurstGroupCell ()

@property (nonatomic, strong) BGBurstGroupView *burstGroupView;

@end


@implementation BGBurstGroupCell

- (instancetype)initWithFrame:(CGRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.burstGroupView = [[BGBurstGroupView alloc] initWithFrame:self.contentView.bounds];
        self.burstGroupView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.burstGroupView];
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

- (void)prepareForReuse {
    self.burstGroupView.assets = nil;
}

@end
