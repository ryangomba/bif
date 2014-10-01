// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"

@class BGBurstGroupDataSource;
@protocol BGBurstGroupDataSourceDelegate <NSObject>

- (void)burstGroupDataSource:(BGBurstGroupDataSource *)dataSource didUpdateBurstGroups:(NSArray *)burstGroups;

@end

@interface BGBurstGroupDataSource : NSObject

@property (nonatomic, weak) id<BGBurstGroupDataSourceDelegate> delegate;

@end
