#import "BGDataSourceUpdate.h"

@implementation BGDataSourceUpdate

+ (instancetype)updateFromObjects:(NSArray *)oldObjects toObjects:(NSArray *)newObjects {
    BGDataSourceUpdate *update = [[BGDataSourceUpdate alloc] init];
    update.objects = newObjects;
    
    NSMutableIndexSet *deletedIndexes = [NSMutableIndexSet indexSet];
    [oldObjects enumerateObjectsUsingBlock:^(NSObject *oldObject, NSUInteger i, BOOL *stop) {
        if (![newObjects containsObject:oldObject]) {
            [deletedIndexes addIndex:i];
        }
    }];
    update.deletedIndexes = deletedIndexes;
    
    NSMutableIndexSet *insertedIndexes = [NSMutableIndexSet indexSet];
    [newObjects enumerateObjectsUsingBlock:^(NSObject *newObject, NSUInteger i, BOOL *stop) {
        if (![oldObjects containsObject:newObject]) {
            [insertedIndexes addIndex:i];
        }
    }];
    update.insertedIndexes = insertedIndexes;
    
    return update;
}

@end
