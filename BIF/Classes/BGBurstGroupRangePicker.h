//
//  BGBurstGroupRangePickerView.h
//  BurstGIF
//
//  Created by Ryan Gomba on 6/8/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "BGBurstGroup.h"

@class BGBurstGroupRangePicker;
@protocol BGBurstGroupRangePickerDelegate <NSObject>

- (void)burstGroupRangePickerDidBeginAdjustingRange:(BGBurstGroupRangePicker *)picker;
- (void)burstGroupRangePickerDidUpdateRange:(BGBurstGroupRangePicker *)picker frameIndex:(NSUInteger)frameIndex;
- (void)burstGroupRangePickerDidEndAdjustingRange:(BGBurstGroupRangePicker *)picker;

@end

@interface BGBurstGroupRangePicker : UIView

@property (nonatomic, strong) BGBurstGroup *burstGroup;

@property (nonatomic, weak) id<BGBurstGroupRangePickerDelegate> delegate;

@end
