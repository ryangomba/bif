@import UIKit;
#import "BGBurstGroup.h"
#import "BGBurstGroupRangePicker.h"

@interface BGBurstGroupCell : UICollectionViewCell

@property (nonatomic, strong) BGBurstGroup *burstGroup;

- (BGBurstGroupRangePicker *)stealRangePickerView;
- (void)returnRangePickerView:(BGBurstGroupRangePicker *)rangePickerView;

@end
