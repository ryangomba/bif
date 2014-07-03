//
//  CHBurstGroupFetcher.m
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGBurstGroupFetcher.h"

#import "BGDatabase.h"

@implementation BGBurstGroupFetcher

+ (void)fetchBurstGroupsWithCompletion:(void(^)(NSArray *burstGroups))completion {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        PHFetchOptions *options = [[PHFetchOptions alloc] init];
//        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
//        
//        PHFetchResult *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
//        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger i, BOOL *stop) {
//            [self processAsset:asset];
//            *stop = YES;
//        }];
//    });
//    
//    return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        options.includeAllBurstAssets = YES;
        
        NSMutableDictionary *burstGroupsMap = [NSMutableDictionary dictionary];
        
        PHFetchResult *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger i, BOOL *stop) {
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
        
        NSArray *burstGroups = [burstGroupsMap.allValues sortedArrayUsingComparator:^NSComparisonResult(BGBurstGroup *group1, BGBurstGroup *group2) {
            return [group2.creationDate compare:group1.creationDate];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(burstGroups);
        });
    });
}

+ (void)processAsset:(PHAsset *)asset {
    BOOL canDo = [asset canPerformEditOperation:PHAssetEditOperationContent];
    NSAssert(canDo, @"Ugh");
    
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    [asset requestContentEditingInputWithOptions:options completionHandler:
     ^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
         CIImage *inputImage = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
         CIImage *outputImage = [inputImage imageByApplyingTransform:CGAffineTransformMakeRotation(M_PI_2)];
//         CIImage *outputImage = [inputImage imageByCroppingToRect:CGRectMake(0.0, 0.0, 50.0, 50.0)];
         CIContext *context = [CIContext contextWithOptions:nil];
         CGImageRef outputCGImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
         UIImage *outputUIImage = [UIImage imageWithCGImage:outputCGImage];
         CGImageRelease(outputCGImage);
         NSData *JPEGData = UIImageJPEGRepresentation(outputUIImage, 0.95);
         
         NSError *writingError = nil;
         PHContentEditingOutput *contentEditingOutput = [[PHContentEditingOutput alloc] initWithContentEditingInput:contentEditingInput];
         NSURL *outputURL = contentEditingOutput.renderedContentURL;
         contentEditingOutput.adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:@"com.appthat.BurstGIF" formatVersion:@"1.0" data:[@"scale" dataUsingEncoding:NSUTF8StringEncoding]];
         [JPEGData writeToURL:outputURL options:NSDataWritingAtomic error:&writingError];
         
         [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
             PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest changeRequestForAsset:asset];
//             changeRequest.contentEditingOutput = contentEditingOutput;
//             changeRequest.favorite = YES;
             [changeRequest revertAssetToOriginal];
             
         } completionHandler:^(BOOL success, NSError *error) {
             NSLog(@"changed? %d %@", success, error);
         }];
    }];
}

@end
