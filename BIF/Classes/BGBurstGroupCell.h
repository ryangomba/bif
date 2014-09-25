// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"
#import "BGBurstGroupView.h"

@interface BGBurstGroupCell : UICollectionViewCell

@property (nonatomic, strong) BGBurstGroup *burstGroup;

- (BGBurstGroupView *)stealBurstGroupView;
- (void)returnBurstGroupView:(BGBurstGroupView *)burstGroupView;

@end
