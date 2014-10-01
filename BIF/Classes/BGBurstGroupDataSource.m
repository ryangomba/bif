// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupDataSource.h"

#import "BGDatabase.h"
#import <YapDatabase/YapDatabase.h>

@interface BGBurstGroupDataSource ()

@property (nonatomic, strong) YapDatabaseConnection *connection;
@property (nonatomic, strong) NSArray *burstGroups;

@end

@implementation BGBurstGroupDataSource

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        YapDatabase *database = [BGDatabase database];
        self.connection = [database newConnection];
        [self.connection beginLongLivedReadTransaction];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:database];
        
        [self fetchBurstGroups];
    }
    return self;
}

- (void)setDelegate:(id<BGBurstGroupDataSourceDelegate>)delegate {
    _delegate = delegate;

    if (self.burstGroups) {
        [self.delegate burstGroupDataSource:self didFetchBurstGroups:self.burstGroups];
    }
}

- (void)onDatabaseModified:(NSNotification *)notification {
    NSArray *notifications = [self.connection beginLongLivedReadTransaction];
    if (notifications.count > 0) {
        [self fetchBurstGroups];
    }
}

- (void)fetchBurstGroups {
    NSMutableArray *burstGroups = [NSMutableArray array];
    [self.connection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray *keys = [transaction allKeysInCollection:kBurstGroupsKey];
        [transaction enumerateObjectsForKeys:keys inCollection:kBurstGroupsKey unorderedUsingBlock:
         ^(NSUInteger keyIndex, id object, BOOL *stop) {
             [burstGroups addObject:object];
        }];
    } completionBlock:^{
        [burstGroups sortUsingComparator:^NSComparisonResult(BGBurstGroup *group1, BGBurstGroup *group2) {
            return [group2.creationDate compare:group1.creationDate];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.burstGroups = burstGroups;
            [self.delegate burstGroupDataSource:self didFetchBurstGroups:self.burstGroups];
        });
    }];
}

@end
