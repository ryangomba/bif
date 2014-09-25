// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"
#import "BGBurstGroupRangePicker.h"

@interface BGBurstGroupCell : UICollectionViewCell

@property (nonatomic, strong) BGBurstGroup *burstGroup;

- (BGBurstGroupRangePicker *)stealRangePickerView;
- (void)returnRangePickerView:(BGBurstGroupRangePicker *)rangePickerView;

@end
