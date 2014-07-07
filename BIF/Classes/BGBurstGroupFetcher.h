// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@import Photos;

#import "BGBurstGroup.h"

@class BGBurstGroupFetcher;
@protocol BGBurstGroupFetcherDelegate <NSObject>

- (void)burstGroupFetcher:(BGBurstGroupFetcher *)fetcher didFetchBurstGroups:(NSArray *)burstGroups;

@end

@interface BGBurstGroupFetcher : NSObject

@property (nonatomic, weak) id<BGBurstGroupFetcherDelegate> delegate;

- (void)fetchBurstGroups;

@end
