// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupCell.h"

@interface BGBurstGroupCell ()

@property (nonatomic, strong) BGBurstGroupRangePicker *rangePickerView;

@end


@implementation BGBurstGroupCell

- (instancetype)initWithFrame:(CGRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.rangePickerView = [[BGBurstGroupRangePicker alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:self.rangePickerView];
    }
    return self;
}

- (void)setBurstGroup:(BGBurstGroup *)burstGroup {
    if (burstGroup == _burstGroup) {
        return;
    }
    
    _burstGroup = burstGroup;

    self.rangePickerView.burstGroup = burstGroup;
}

- (BGBurstGroupRangePicker *)stealRangePickerView {
    return self.rangePickerView;
}

- (void)returnRangePickerView:(BGBurstGroupRangePicker *)rangePickerView {
    rangePickerView.frame = self.contentView.bounds;
    [self.contentView addSubview:self.rangePickerView];
}

- (void)prepareForReuse {
    self.rangePickerView.burstGroup = nil;
}

@end
