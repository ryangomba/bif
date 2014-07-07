//
//  CHBurstGroupFetcher.h
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

@import Foundation;
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
