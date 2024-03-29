@import UIKit;
#import "BGBurstGroup.h"
#import "BGBurstGroupView.h"

@class BGBurstGroupRangePicker;
@protocol BGBurstGroupRangePickerDelegate <NSObject>

- (void)burstGroupRangePickerDidBeginAdjustingRange:(BGBurstGroupRangePicker *)picker;
- (void)burstGroupRangePickerDidUpdateRange:(BGBurstGroupRangePicker *)picker frameIndex:(NSUInteger)frameIndex;
- (void)burstGroupRangePickerDidEndAdjustingRange:(BGBurstGroupRangePicker *)picker;

@end

@interface BGBurstGroupRangePicker : UIView

@property (nonatomic, strong) BGBurstGroup *burstGroup;
@property (nonatomic, assign) BGBurstPhoto *currentPhoto;

@property (nonatomic, weak) id<BGBurstGroupRangePickerDelegate> delegate;

- (void)setEditable:(BOOL)editable animated:(BOOL)animated;

@end
