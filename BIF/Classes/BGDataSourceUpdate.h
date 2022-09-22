@import Foundation;

@interface BGDataSourceUpdate : NSObject

@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, strong) NSIndexSet *deletedIndexes;
@property (nonatomic, strong) NSIndexSet *insertedIndexes;

+ (instancetype)updateFromObjects:(NSArray *)oldObjects toObjects:(NSArray *)newObjects;

@end
