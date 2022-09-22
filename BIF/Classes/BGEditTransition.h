#import "BGBurstGroup.h"
#import "BGBurstGroupRangePicker.h"

@protocol BGEditTransitionListController <NSObject>

- (CGRect)rectForRangePickerViewForBurstGroup:(BGBurstGroup *)burstGroup;
- (BGBurstGroupRangePicker *)stealRangePickerViewForBurstGroup:(BGBurstGroup *)burstGroup;
- (void)returnRangePickerView:(BGBurstGroupRangePicker *)rangePickerView forBurstGroup:(BGBurstGroup *)burstGroup;

@end

@protocol BGEditTransitionPreviewController <NSObject>

- (CGRect)rectForRangePickerView;
- (BGBurstGroupRangePicker *)stealRangePickerView;
- (void)prepareRangePickerView:(BGBurstGroupRangePicker *)rangePickerView;
- (void)placeRangePickerView:(BGBurstGroupRangePicker *)rangePickerView;

- (UIView *)mediaView;
- (void)display:(BOOL)display;

@end

@interface BGEditTransition : NSObject<UIViewControllerTransitioningDelegate>

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup
                    fromController:(id<BGEditTransitionListController>)fromController
                      toController:(id<BGEditTransitionPreviewController>)toController;

@end
