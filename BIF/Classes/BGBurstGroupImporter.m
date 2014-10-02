// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupImporter.h"

@import Photos;

#import "BGDatabase.h"
#import "UIImage+Resize.h"
#import "BIFHelpers.h"

@interface BGBurstAssetsGroup : NSObject

@property (nonatomic, strong) NSString *burstIdentifier;
@property (nonatomic, strong) NSMutableArray *assets;

@property (readonly) PHAsset *firstAsset;
@property (readonly) PHAsset *lastAsset;

@end

@implementation BGBurstAssetsGroup

- (instancetype)initWithBurstIdentifier:(NSString *)burstIdentifier {
    if (self = [super init]) {
        self.burstIdentifier = burstIdentifier;
        self.assets = [NSMutableArray array];
    }
    return self;
}

- (PHAsset *)firstAsset {
    return self.assets.firstObject;
}

- (PHAsset *)lastAsset {
    return self.assets.lastObject;
}

@end


@interface BGBurstGroupImporter ()<PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHFetchResult *fetchResult;

@property (nonatomic, strong, readwrite) NSOperationQueue *importQueue;

@end


@implementation BGBurstGroupImporter

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        self.importQueue = [[NSOperationQueue alloc] init];
        self.importQueue.maxConcurrentOperationCount = 2;
        
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)importCameraBursts {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doImportCameraBursts];
    });
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if ([changeInstance changeDetailsForFetchResult:self.fetchResult]) {
        [self importCameraBursts];
    }
}

- (void)doImportCameraBursts {
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
        BGBurstAssetsGroup *assetsGroup = burstGroupsMap[burstID];
        if (!assetsGroup) {
            assetsGroup = [[BGBurstAssetsGroup alloc] initWithBurstIdentifier:burstID];
            burstGroupsMap[burstID] = assetsGroup;
        }
        [assetsGroup.assets addObject:asset];
    }];
    
    // filter burst groups for ones that are too short
    
    NSMutableArray *assetGroups = [burstGroupsMap.allValues mutableCopy];
    NSPredicate *minLengthPredicate = [NSPredicate predicateWithFormat:@"assets.@count >= %d", kBGMinPhotosPerBurst];
    [assetGroups filterUsingPredicate:minLengthPredicate];
    
    // order by recency
    
    [assetGroups sortUsingComparator:^NSComparisonResult(BGBurstAssetsGroup *group1, BGBurstAssetsGroup *group2) {
        return [group2.firstAsset.creationDate compare:group1.firstAsset.creationDate];
    }];
    
    // fetch or create burst groups
    
    for (BGBurstAssetsGroup *assetGroup in assetGroups) {
        [self.importQueue addOperationWithBlock:^{
            [self importAssetsGroupIfNecessary:assetGroup];
        }];
    }
}

- (void)importAssetsGroupIfNecessary:(BGBurstAssetsGroup *)assetGroup {
    BGBurstGroup *burstGroup = [BGDatabase burstGroupForBurstIdentifier:assetGroup.burstIdentifier];
    if (burstGroup) {
        // already exists
        return;
    }
    
//    NSLog(@"Creating new burst group %@", assetGroup.burstIdentifier);

    burstGroup = [[BGBurstGroup alloc] init];
    burstGroup.burstIdentifier = assetGroup.burstIdentifier;
    burstGroup.creationDate = assetGroup.firstAsset.creationDate;
    burstGroup.startFrameIdentifier = assetGroup.firstAsset.localIdentifier;
    burstGroup.endFrameIdentifier = assetGroup.lastAsset.localIdentifier;
    
    NSMutableArray *photos = [NSMutableArray array];
    for (PHAsset *asset in assetGroup.assets) {
        BGBurstPhoto *photo = [[BGBurstPhoto alloc] init];
        photo.localIdentifier = asset.localIdentifier;
        photo.creationDate = asset.creationDate;

        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionOriginal;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.synchronous = YES;
        
        CGFloat aspectRatio = asset.pixelWidth / (CGFloat)asset.pixelHeight;
        NSInteger targetWidth = roundf(MAX(aspectRatio, 1.0) * kBGFullscreenImageMinEdgeSize);
        NSInteger targetHeight = roundf(MAX(1.0 / aspectRatio, 1.0) * kBGFullscreenImageMinEdgeSize);
        CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
        
        BOOL (^quickImportBlock)(void) = ^{
            __block BOOL quickImportWorked = NO;
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                       targetSize:targetSize
                                                      contentMode:PHImageContentModeAspectFill
                                                          options:options resultHandler:
             ^(UIImage *result, NSDictionary *info) {
                 if (result) {
                     quickImportWorked = YES;
                     [self saveImage:result forPhoto:photo];
                 }
             }];
            return quickImportWorked;
        };
        
        void (^slowImportBlock)(void) = ^{
            NSLog(@"Importing slowly");
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                       targetSize:PHImageManagerMaximumSize
                                                      contentMode:PHImageContentModeDefault
                                                          options:options resultHandler:
             ^(UIImage *result, NSDictionary *info) {
                 NSAssert(result, @"No image!!!!!!");
                 [self saveImage:result forPhoto:photo];
             }];
        };
        
        @autoreleasepool {
//            CFTimeInterval startTime = CACurrentMediaTime();
            if (!quickImportBlock()) {
                slowImportBlock();
            }
//            NSLog(@"Fetch time %f", CACurrentMediaTime() - startTime);
        }
        
        [photos addObject:photo];
    }
    burstGroup.photos = photos;
    
    [BGDatabase saveBurstGroup:burstGroup];
    
//    NSLog(@"Finished creating new burst group %@", assetGroup.burstIdentifier);
}

- (void)saveImage:(UIImage *)image forPhoto:(BGBurstPhoto *)photo {
//    CFTimeInterval startTime = CACurrentMediaTime();
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSString *assetName = [photo.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    
    NSError *error = nil;
    
    UIImage *fullscreenImage;
    if (MIN(image.size.width, image.size.height) == kBGFullscreenImageMinEdgeSize) {
        fullscreenImage = image;
    } else {
        fullscreenImage = [image resizedImageWithBounds:CGSizeMake(kBGFullscreenImageMinEdgeSize, kBGFullscreenImageMinEdgeSize)];
    }
    NSString *fullscreenImageFilename = [NSString stringWithFormat:@"%@_%lux%lu.jpg", assetName, (long)fullscreenImage.size.width, (long)fullscreenImage.size.height];
    NSURL *fullscreenImageFileURL = [documentsDirectoryURL URLByAppendingPathComponent:fullscreenImageFilename];
    if ([UIImageJPEGRepresentation(fullscreenImage, kBGJPEGCompressionQuality) writeToURL:fullscreenImageFileURL options:NSDataWritingAtomic error:&error]) {
        photo.fullscreenFilePath = fullscreenImageFileURL.path;
        photo.aspectRatio = fullscreenImage.size.width / fullscreenImage.size.height;
    } else {
        NSAssert(NO, error.localizedDescription);
    }
    
    UIImage *thumbnailImage = [fullscreenImage squareThumbnailImageOfSize:kBGThumbnailImageSize];
    NSString *thumbnailImageFilename = [NSString stringWithFormat:@"%@_%lux%lu.jpg", assetName, (long)thumbnailImage.size.width, (long)thumbnailImage.size.height];
    NSURL *thumbnailImageFileURL = [documentsDirectoryURL URLByAppendingPathComponent:thumbnailImageFilename];
    if ([UIImageJPEGRepresentation(thumbnailImage, kBGJPEGCompressionQuality) writeToURL:thumbnailImageFileURL options:NSDataWritingAtomic error:&error]) {
        photo.thumbnailFilePath = thumbnailImageFileURL.path;
    } else {
        NSAssert(NO, error.localizedDescription);
    }
    
//    NSLog(@"Resize time %f", CACurrentMediaTime() - startTime);
}

@end
