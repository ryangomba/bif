// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstInfo.h"

@interface BGDatabase : NSObject

+ (BGBurstInfo *)burstInfoForBurstIdentifier:(NSString *)burstIdentifier;
+ (void)saveBurstInfo:(BGBurstInfo *)burstInfo;

@end
