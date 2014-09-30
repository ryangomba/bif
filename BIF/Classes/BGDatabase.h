// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"

@interface BGDatabase : NSObject

+ (void)wipeDatabase;

+ (BGBurstGroup *)burstGroupForBurstIdentifier:(NSString *)burstIdentifier;
+ (void)saveBurstGroup:(BGBurstGroup *)burstGroup;

@end
