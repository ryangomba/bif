//
//  CHBurstGroupFetcher.m
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGBurstGroupFetcher.h"

#import "BGDatabase.h"

static NSInteger kMinPhotosPerBurst = 5;

@interface BGBurstGroupFetcher ()<PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHFetchResult *fetchResult;

@end


@implementation BGBurstGroupFetcher

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)fetchBurstGroups {
    NSAssert(self.delegate, @"Register an update block before fetching");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doFetchBurstGroupsWithCompletion:^(NSArray *burstGroups) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate burstGroupFetcher:self didFetchBurstGroups:burstGroups];
            });
        }];
    });
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (self.delegate && [changeInstance changeDetailsForFetchResult:self.fetchResult]) {
        [self fetchBurstGroups];
    }
}

- (void)doFetchBurstGroupsWithCompletion:(void(^)(NSArray *burstGroups))completion {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    options.includeAllBurstAssets = YES;
    
    NSMutableDictionary *burstGroupsMap = [NSMutableDictionary dictionary];
    
    self.fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    [self.fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger i, BOOL *stop) {
        NSString *burstID = asset.burstIdentifier;
        if (!burstID) {
            return;
        }
        BGBurstGroup *burstGroup = burstGroupsMap[burstID];
        if (!burstGroup) {
            burstGroup = [[BGBurstGroup alloc] init];
            burstGroupsMap[burstID] = burstGroup;
            burstGroup.burstIdentifier = burstID;
            
            BGBurstInfo *savedInfo = [BGDatabase burstInfoForBurstIdentifier:burstID];
            burstGroup.burstInfo = savedInfo ?: [[BGBurstInfo alloc] initWithBurstIdentifier:burstID];
        }
        [burstGroup.photos addObject:asset];
        burstGroup.creationDate = [asset.creationDate earlierDate:burstGroup.creationDate];
    }];
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"photos.@count >= %d", kMinPhotosPerBurst];
    NSArray *burstGroups = [burstGroupsMap.allValues filteredArrayUsingPredicate:filterPredicate];
    burstGroups = [burstGroups sortedArrayUsingComparator:^NSComparisonResult(BGBurstGroup *group1, BGBurstGroup *group2) {
        return [group2.creationDate compare:group1.creationDate];
    }];
    completion(burstGroups);
}

@end
