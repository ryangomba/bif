//
//  CHBurstPreviewView.m
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGBurstPreviewView.h"

#import "UIImage+Resize.h"

@import Photos;

@interface BGBurstPreviewView ()

@property (nonatomic, strong) NSMutableArray *assetImages;
@property (nonatomic, strong) NSMutableArray *ongoingImageRequestIDs;

@property (nonatomic, strong) UIImageView *animatedImageView;
@property (nonatomic, strong) UIImageView *staticImageView;

@end


@implementation BGBurstPreviewView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.animatedImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.animatedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.animatedImageView.clipsToBounds = YES;
        self.animatedImageView.animationRepeatCount = 0;
        [self addSubview:self.animatedImageView];
        
        self.staticImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.staticImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.staticImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.staticImageView.clipsToBounds = YES;
        [self addSubview:self.staticImageView];
        
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
        PHImageRequestID requestID = [requestIDValue unsignedIntegerValue];
        [[PHImageManager defaultManager] cancelImageRequest:requestID];
    }
}

- (void)fetchImages {
    CGSize imageSize = self.bounds.size;
    imageSize.width *= [UIScreen mainScreen].scale;
    imageSize.height *= [UIScreen mainScreen].scale;
    
    for (PHAsset *asset in self.assets) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        
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
                             self.assetImages[index] = result;
                             
                             // HACK
                             if (asset.pixelHeight > asset.pixelWidth) {
                                 self.animatedImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
                             }
                             
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

@end
