// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstPreviewView.h"

#import "UIImage+Resize.h"
#import "RGGeometry.h"

#define kMaximumZoomScale 2.0

@import Photos;

@interface BGBurstPreviewView ()<UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *assetImages;
@property (nonatomic, strong) NSMutableArray *ongoingImageRequestIDs;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *animatedImageView;
@property (nonatomic, strong) UIImageView *staticImageView;

@end


@implementation BGBurstPreviewView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.bounces = NO;
        self.scrollView.bouncesZoom = NO;
        self.scrollView.delegate = self;
        [self addSubview:self.scrollView];
        
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentView.clipsToBounds = YES;
        [self.scrollView addSubview:self.contentView];
        
        self.animatedImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.animatedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.animatedImageView.animationRepeatCount = 0;
        [self.contentView addSubview:self.animatedImageView];
        
        self.staticImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.staticImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.staticImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.staticImageView];
        
        self.ongoingImageRequestIDs = [NSMutableArray array];
    }
    return self;
}

- (void)setAssets:(NSArray *)assets {
    [self cancelImageFetchRequests];
    
    _assets = assets;
    
    self.assetImages = [NSMutableArray array];
    for (NSInteger i = 0; i < assets.count; i++) {
        [self.assetImages addObject:[NSNull null]];
    }
    
    [self prepareImageViews];
    
    [self fetchImages];
}

- (NSArray *)allImagesInRange {
    if (NSEqualRanges(self.range, NSMakeRange(0, 0))) {
        return self.assetImages;
    }
    return [self.assetImages subarrayWithRange:self.range];
}

- (NSArray *)allImagesInRangeWithLoopModeApplied {
    NSMutableArray *images = [[NSMutableArray alloc] init];
    
    switch (self.loopMode) {
        case LoopModeLoop: {
            [images addObjectsFromArray:self.allImagesInRange];
        } break;
            
        case LoopModeReverse: {
            [images addObjectsFromArray:self.allImagesInRange];
            NSArray *imagesReversed = [self.allImagesInRange reverseObjectEnumerator].allObjects;
            if (imagesReversed.count > 2) {
                for (NSInteger i = 1; i < imagesReversed.count - 1; i++) {
                    [images addObject:imagesReversed[i]];
                }
            }
        } break;
    }
    
    return images;
}

- (void)cancelImageFetchRequests {
    for (NSNumber *requestIDValue in self.ongoingImageRequestIDs) {
        PHImageRequestID requestID = [requestIDValue intValue];
        [[PHImageManager defaultManager] cancelImageRequest:requestID];
    }
}

- (void)prepareImageViews {
    NSAssert(self.assets.count > 0, @"No assets");
    
    PHAsset *firstAsset = self.assets.firstObject;
    CGFloat burstAspectRatio = firstAsset.pixelWidth / (CGFloat)firstAsset.pixelHeight;
    CGSize imageSize = RGSizeOuterSizeWithAspectRatio(self.bounds.size, burstAspectRatio);
    
    self.contentView.frame = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
    self.scrollView.contentSize = CGSizeMake(imageSize.width, imageSize.height);
    
    CGFloat imageViewX = (imageSize.width - self.bounds.size.width) / 2;
    CGFloat imageViewY = (imageSize.height - self.bounds.size.height) / 2;
    self.scrollView.contentOffset = CGPointMake(imageViewX, imageViewY);
    
    self.scrollView.maximumZoomScale = kMaximumZoomScale;
}

- (void)fetchImages {
    NSAssert(self.assets.count > 0, @"No assets");
    
    CGSize imageSize = self.animatedImageView.frame.size;
    imageSize.width *= [UIScreen mainScreen].scale;
    imageSize.height *= [UIScreen mainScreen].scale;
    
    for (PHAsset *asset in self.assets) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        options.version = PHImageRequestOptionsVersionOriginal;
        options.networkAccessAllowed = YES;
        
        PHImageRequestID requestID;
        requestID = [[PHImageManager defaultManager] requestImageForAsset:asset
                                                               targetSize:imageSize
                                                              contentMode:PHImageContentModeAspectFill
                                                                  options:options
                                                            resultHandler:^(UIImage *result, NSDictionary *info)
                     {
                         if (!result) {
                             NSLog(@"WTF, no image, no info");
                             return;
                         }
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self.ongoingImageRequestIDs removeObject:@(requestID)];
                             
                             NSInteger index = [self.assets indexOfObject:asset];
                             self.assetImages[index] = result;
                             
                             UIImageOrientation orientation = [info[@"PHImageFileOrientationKey"] integerValue];
                             CGAffineTransform transform = [UIImage transformForImageOfSize:result.size orientation:orientation newSize:imageSize];
                             self.animatedImageView.transform = transform;
                             
                             [self updateImages];
                         });
                     }];
        [self.ongoingImageRequestIDs addObject:@(requestID)];
    }
}

- (BOOL)isLoaded {
    return ![self.assetImages containsObject:[NSNull null]];
}

- (void)setFramesPerSecond:(CGFloat)framesPerSecond {
    _framesPerSecond = framesPerSecond;
    
    [self updateImages];
}

- (void)setLoopMode:(LoopMode)loopMode {
    _loopMode = loopMode;
    
    [self updateImages];
}

- (void)setRange:(NSRange)range {
    _range = range;
    
    [self updateImages];
}

- (void)setAnimated:(BOOL)animated {
    _animated = animated;
    
    if (animated) {
        self.staticIndex = self.range.location;
        if (self.isLoaded) {
            [self startAnimating];
        }
    } else {
        [self stopAnimating];
    }
}

- (void)updateImages {
    if (self.isLoaded) {
        self.staticImageView.image = self.assetImages[self.staticIndex];
        
        NSArray *animationImages = [self allImagesInRangeWithLoopModeApplied];
        self.animatedImageView.animationImages = animationImages;
        
        self.animatedImageView.animationDuration = animationImages.count * (1.0 / self.framesPerSecond);
        if (self.animated) {
            [self startAnimating];
        }
    }
}

- (void)startAnimating {
    self.staticImageView.hidden = YES;
    [self.animatedImageView startAnimating];
}

- (void)stopAnimating {
    self.staticImageView.hidden = NO;
    [self.animatedImageView stopAnimating];
}


#pragma mark -
#pragma mark Cropping

- (void)setCropInfo:(CGRect)cropInfo {
    NSAssert(self.assets, @"setAssets: should be called first");
    
    if (CGRectEqualToRect(cropInfo, CGRectZero)) {
        return;
    }
    
    CGFloat contentOffsetX = cropInfo.origin.x * self.scrollView.contentSize.width;
    CGFloat contentOffsetY = cropInfo.origin.y * self.scrollView.contentSize.height;
    CGFloat contentWidth = cropInfo.size.width * self.scrollView.contentSize.width;
    CGFloat contentHeight = cropInfo.size.height * self.scrollView.contentSize.height;
    
    CGRect zoomRect = CGRectMake(contentOffsetX, contentOffsetY, contentWidth, contentHeight);
    [self.scrollView zoomToRect:zoomRect animated:NO];
}

- (CGRect)cropInfo {
    CGFloat normalizedX = self.scrollView.contentOffset.x / self.scrollView.contentSize.width;
    CGFloat normalizedY = self.scrollView.contentOffset.y / self.scrollView.contentSize.height;
    
    CGFloat zoomSize = MIN(self.scrollView.contentSize.width, self.scrollView.contentSize.height) / self.scrollView.zoomScale;
    CGFloat normalizedWidth = zoomSize / self.scrollView.contentSize.width;
    CGFloat normalizedHeight = zoomSize / self.scrollView.contentSize.height;
    
    return CGRectMake(normalizedX, normalizedY, normalizedWidth, normalizedHeight);
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.contentView;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.delegate burstPreviewView:self didChangeCropInfo:self.cropInfo];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [self.delegate burstPreviewView:self didChangeCropInfo:self.cropInfo];
}

@end
