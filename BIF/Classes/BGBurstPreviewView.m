// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstPreviewView.h"

#import "UIImage+Resize.h"
#import "RGGeometry.h"

#define kMaximumZoomScale 2.0

@interface BGBurstPreviewView ()<UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *assetImages;

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
        
        // border and shadow
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = 4.0;
        
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
}

- (void)setPhotos:(NSArray *)photos {
    _photos = photos;
    
    self.assetImages = [NSMutableArray array];
    for (NSInteger i = 0; i < photos.count; i++) {
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

- (void)prepareImageViews {
    NSAssert(self.photos.count > 0, @"No photos");
    
    BGBurstPhoto *firstPhoto = self.photos.firstObject;
    CGSize imageSize = RGSizeOuterSizeWithAspectRatio(self.bounds.size, firstPhoto.aspectRatio);
    
    self.contentView.frame = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
    self.scrollView.contentSize = CGSizeMake(imageSize.width, imageSize.height);
    
    CGFloat imageViewX = (imageSize.width - self.bounds.size.width) / 2;
    CGFloat imageViewY = (imageSize.height - self.bounds.size.height) / 2;
    self.scrollView.contentOffset = CGPointMake(imageViewX, imageViewY);
    
    self.scrollView.maximumZoomScale = kMaximumZoomScale;
}

- (void)fetchImages {
    NSAssert(self.photos.count > 0, @"No photos");
    
    for (BGBurstPhoto *photo in self.photos) {
        NSInteger index = [self.photos indexOfObject:photo];
        self.assetImages[index] = [UIImage imageWithContentsOfFile:photo.fullscreenFilePath];
        [self updateImages];
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
        if (self.isLoaded && !self.paused) {
            [self startAnimating];
        }
    } else {
        [self stopAnimating];
    }
}

- (void)setPaused:(BOOL)paused {
    _paused = paused;
    
    if (self.isLoaded && !paused) {
        [self startAnimating];
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
    NSAssert(self.photos, @"setPhotos: should be called first");
    
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
