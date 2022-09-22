#import "BGBurstGroup.h"

@class YapDatabase;

static NSString * const kBurstGroupsKey = @"burstGroups";

@interface BGDatabase : NSObject

+ (YapDatabase *)database;

+ (void)wipeDatabase;

+ (BGBurstGroup *)burstGroupForBurstIdentifier:(NSString *)burstIdentifier;
+ (void)saveBurstGroup:(BGBurstGroup *)burstGroup;

@end
