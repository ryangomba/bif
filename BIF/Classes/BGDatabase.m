#import "BGDatabase.h"

#import <YapDatabase/YapDatabase.h>

@implementation BGDatabase

+ (YapDatabase *)database {
    static YapDatabase *database;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSString *databasePath = [applicationSupportDirectory stringByAppendingString:@"database.sqlite"];
        database = [[YapDatabase alloc] initWithPath:databasePath];
    });
    return database;
}

+ (void)wipeDatabase {
    YapDatabaseConnection *connection = [self.database newConnection];
    [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInAllCollections];
    }];
}

+ (BGBurstGroup *)burstGroupForBurstIdentifier:(NSString *)burstIdentifier {
    __block BGBurstGroup *burstGroup;
    YapDatabaseConnection *connection = [self.database newConnection];
    [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
         burstGroup = [transaction objectForKey:burstIdentifier inCollection:kBurstGroupsKey];
    }];
    return burstGroup;
}

+ (void)saveBurstGroup:(BGBurstGroup *)burstGroup {
    YapDatabaseConnection *connection = [self.database newConnection];
    [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:burstGroup forKey:burstGroup.burstIdentifier inCollection:kBurstGroupsKey];
    }];
}

@end
