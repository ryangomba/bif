// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstInfo.h"

@interface BGBurstGroup : NSObject

@property (nonatomic, strong) NSString *burstIdentifier;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, readonly) NSRange range;

@property (nonatomic, strong) BGBurstInfo *burstInfo;

@end
