// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroupView.h"

#define kMaxNumberOfImages 5

@import Photos;

@interface BGBurstGroupView ()

@property (nonatomic, strong) NSMutableArray *imageViews;

@end

@implementation BGBurstGroupView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
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

- (void)setPhotos:(NSArray *)photos {
    _photos = [self evenlySpacedSubsetOfSize:kMaxNumberOfImages forArray:photos];
    
    [self fetchImages];
}

- (CGSize)imageSize {
    CGFloat imageViewWidth = self.bounds.size.width / kMaxNumberOfImages;
    CGFloat imageViewHeight = self.bounds.size.height;
    return CGSizeMake(imageViewWidth, imageViewHeight);
}

- (void)fetchImages {
    CGSize imageSize = [self imageSize];
    imageSize.width *= [UIScreen mainScreen].scale;
    imageSize.height *= [UIScreen mainScreen].scale;
    
    for (BGBurstPhoto *photo in self.photos) {
        NSInteger index = [self.photos indexOfObject:photo];
        UIImageView *imageView = self.imageViews[index];
        imageView.image = [UIImage imageWithContentsOfFile:photo.thumbnailFilePath];
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
        
        imageView.hidden = i >= kMaxNumberOfImages;
    }
}

@end
