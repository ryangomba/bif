// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupFetcher.h"

#import "BGDatabase.h"

// HACK
#import "UIImage+Resize.h"
static NSInteger kMinEdgeSize = 640.0;

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
    self.fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    
    // organize photos into groups of bursts
    
    NSMutableDictionary *burstGroupsMap = [NSMutableDictionary dictionary];
    [self.fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger i, BOOL *stop) {
        NSString *burstID = asset.burstIdentifier;
        if (!burstID) {
            return;
        }
        NSMutableArray *burstGroupAssets = burstGroupsMap[burstID];
        if (!burstGroupAssets) {
            burstGroupAssets = [NSMutableArray array];
            burstGroupsMap[burstID] = burstGroupAssets;
        }
        [burstGroupAssets addObject:asset];
    }];
    
    // filter burst groups for ones that are too short
    
    NSMutableArray *unsatisfactoryBurstIdentifiers = [NSMutableArray array];
    [burstGroupsMap enumerateKeysAndObjectsUsingBlock:^(NSString *burstIdentifier, NSArray *assets, BOOL *stop) {
        if (assets.count < kMinPhotosPerBurst) {
            [unsatisfactoryBurstIdentifiers addObject:burstIdentifier];
        }
    }];
    [burstGroupsMap removeObjectsForKeys:unsatisfactoryBurstIdentifiers];
    
    // fetch or create burst groups
    
    [BGDatabase wipeDatabase]; // TEMP
    
    NSMutableArray *burstGroups = [NSMutableArray array];
    [burstGroupsMap enumerateKeysAndObjectsUsingBlock:^(NSString *burstIdentifier, NSArray *assets, BOOL *stop) {
        BGBurstGroup *burstGroup = [BGDatabase burstGroupForBurstIdentifier:burstIdentifier];
        if (!burstGroup) {
            NSLog(@"Creating new burst group");
            burstGroup = [[BGBurstGroup alloc] init];
            burstGroup.burstIdentifier = burstIdentifier;
            burstGroup.creationDate = ((PHAsset *)assets.firstObject).creationDate;
            burstGroup.startFrameIdentifier = ((PHAsset *)assets.firstObject).localIdentifier;
            burstGroup.endFrameIdentifier = ((PHAsset *)assets.lastObject).localIdentifier;
            burstGroup.text = @"";
            
            NSMutableArray *photos = [NSMutableArray array];
            for (PHAsset *asset in assets) {
                NSLog(@"Importing photo %@", asset.localIdentifier);
                BGBurstPhoto *photo = [[BGBurstPhoto alloc] init];
                photo.aspectRatio = 1.0; // TEMP
                photo.localIdentifier = asset.localIdentifier;
                
                @autoreleasepool {
                    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                    options.version = PHImageRequestOptionsVersionOriginal;
                    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                    options.resizeMode = PHImageRequestOptionsResizeModeExact;
                    options.synchronous = YES;
                    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(120.0, 120.0)/*PHImageManagerMaximumSize*/ contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                        photo.filePath = [self savePhoto:result forAsset:asset];
                    }];
                }
                
                [photos addObject:photo];
            }
            burstGroup.photos = photos;
            [BGDatabase saveBurstGroup:burstGroup];
        }
        [burstGroups addObject:burstGroup];
    }];
    
    // fetch burst groups
    
    [burstGroups sortUsingComparator:^NSComparisonResult(BGBurstGroup *group1, BGBurstGroup *group2) {
        return [group2.creationDate compare:group1.creationDate];
    }];
    
    completion(burstGroups);
}

- (NSString *)savePhoto:(UIImage *)image forAsset:(PHAsset *)asset {
    UIImage *resizedImage = image;// [image resizedImageWithBounds:CGSizeMake(kMinEdgeSize, kMinEdgeSize)];
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSString *filename = [NSString stringWithFormat:@"%@.jpg", [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"-"]];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:filename];
    [UIImageJPEGRepresentation(resizedImage, 0.9) writeToURL:fileURL atomically:YES];
    return fileURL.path;
}

@end
