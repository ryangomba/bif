// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstPreviewView.h"

#import "UIImage+Resize.h"
#import "RGGeometry.h"
#import "BGAnimatedImageView.h"

#define kMaximumZoomScale 2.0

@interface BGBurstPreviewView ()<UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *assetImagePaths;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) BGAnimatedImageView *animatedImageView;
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
        
        self.animatedImageView = [[BGAnimatedImageView alloc] initWithFrame:CGRectZero];
        self.animatedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
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
    
    [self prepareImageViews];
    [self updateImages];
}

- (NSArray *)allPhotosInRange {
    if (NSEqualRanges(self.range, NSMakeRange(0, 0))) {
        return self.photos;
    }
    return [self.photos subarrayWithRange:self.range];
}

- (NSArray *)allPhotosInRangeWithLoopModeApplied {
    switch (self.loopMode) {
        case LoopModeLoop: {
            return self.allPhotosInRange;
        } break;
            
        case LoopModeReverse: {
            NSMutableArray *photos = [[NSMutableArray alloc] init];
            [photos addObjectsFromArray:self.allPhotosInRange];
            NSArray *photosReversed = [self.allPhotosInRange reverseObjectEnumerator].allObjects;
            if (photosReversed.count > 2) {
                for (NSInteger i = 1; i < photosReversed.count - 1; i++) {
                    [photos addObject:photosReversed[i]];
                }
            }
            return photos;
        } break;
    }
}

- (NSArray *)allImagePathsInRangeWithLoopModeApplied {
    return [self.allPhotosInRangeWithLoopModeApplied valueForKey:@"fullscreenFilePath"];
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
        if (!self.paused) {
            [self startAnimating];
        }
    } else {
        [self stopAnimating];
    }
}

- (void)setPaused:(BOOL)paused {
    _paused = paused;
    
    if (!paused) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)updateImages {
    BGBurstPhoto *staticPhoto = self.photos[self.staticIndex];
    NSString *staticPhotoPath = staticPhoto.fullscreenFilePath;
    self.staticImageView.image = [UIImage imageWithContentsOfFile:staticPhotoPath];
    
    self.animatedImageView.imagePaths = [self allImagePathsInRangeWithLoopModeApplied];
    self.animatedImageView.framesPerSecond = self.framesPerSecond;
    
    if (self.animated) {
        [self startAnimating];
    }
}

- (void)startAnimating {
    self.staticImageView.hidden = YES;
    self.animatedImageView.animated = YES;
}

- (void)stopAnimating {
    self.staticImageView.hidden = NO;
    self.animatedImageView.animated = NO;
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
