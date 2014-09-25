// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupView.h"

#define kMaxNumberOfImages 6

@import Photos;

@interface BGBurstGroupView ()

@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, strong) NSMutableArray *ongoingImageRequestIDs;

@end

@implementation BGBurstGroupView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.ongoingImageRequestIDs = [NSMutableArray array];
        self.imageViews = [NSMutableArray array];
        for (NSInteger i = 0; i < kMaxNumberOfImages; i++) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [self addSubview:imageView];
            [self.imageViews addObject:imageView];
        }
        
        [self doLayout];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self doLayout];
}

- (void)setAssets:(NSArray *)assets {
    [self cancelImageFetchRequests];
    
    _assets = [self evenlySpacedSubsetOfSize:kMaxNumberOfImages forArray:assets];
    
    [self fetchImages];
    [self doLayout];
}

- (void)cancelImageFetchRequests {
    for (NSNumber *requestIDValue in self.ongoingImageRequestIDs) {
        PHImageRequestID requestID = [requestIDValue intValue];
        [[PHImageManager defaultManager] cancelImageRequest:requestID];
    }
}

- (CGSize)imageSize {
    CGFloat imageViewWidth = self.bounds.size.width / self.assets.count;
    CGFloat imageViewHeight = self.bounds.size.height;
    return CGSizeMake(imageViewWidth, imageViewHeight);
}

- (void)fetchImages {
    CGSize imageSize = [self imageSize];
    imageSize.width *= [UIScreen mainScreen].scale;
    imageSize.height *= [UIScreen mainScreen].scale;
    
    for (PHAsset *asset in self.assets) {
        PHImageRequestOptions *options = nil;
        PHImageRequestID requestID;
        requestID = [[PHImageManager defaultManager] requestImageForAsset:asset
                                                               targetSize:imageSize
                                                              contentMode:PHImageContentModeAspectFill
                                                                  options:options
                                                            resultHandler:^(UIImage *result, NSDictionary *info)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self.ongoingImageRequestIDs removeObject:@(requestID)];
                             
                             NSInteger index = [self.assets indexOfObject:asset];
                             UIImageView *imageView = self.imageViews[index];
                             imageView.image = result;
                         });
                     }];
        [self.ongoingImageRequestIDs addObject:@(requestID)];
    }
}

- (NSArray *)evenlySpacedSubsetOfSize:(NSInteger)subsetSize forArray:(NSArray *)array {
    if (array.count <= subsetSize) {
        return array;
    }
    
    CGFloat floatingIndex = 0.0;
    NSMutableArray *subsetArray = [NSMutableArray array];
    while (subsetArray.count < subsetSize) {
        NSInteger index = floorf(floatingIndex);
        [subsetArray addObject:array[index]];
        floatingIndex += array.count / (CGFloat)subsetSize;
    }
    return subsetArray;
}

- (void)doLayout {
    CGSize imageSize = [self imageSize];
    
    CGFloat x = 0.0;
    for (NSInteger i = 0; i < self.imageViews.count; i++) {
        UIImageView *imageView = self.imageViews[i];
        imageView.frame = CGRectMake(roundf(x), 0.0, roundf(imageSize.width), roundf(imageSize.height));
        x += imageSize.width;
        
        imageView.hidden = i >= self.assets.count;
    }
}

@end
