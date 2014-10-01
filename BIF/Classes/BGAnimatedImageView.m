// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGAnimatedImageView.h"

@interface BGAnimatedImageView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger frameIndex;

@end

@implementation BGAnimatedImageView

- (void)dealloc {
    [self.displayLink invalidate];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.imageView];
        
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.displayLink.paused = YES;
    }
    return self;
}

- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLinkFired:)];
    }
    return _displayLink;
}

- (void)setFramesPerSecond:(CGFloat)framesPerSecond {
    _framesPerSecond = framesPerSecond;
    
    NSInteger frameInterval = 60 / framesPerSecond;
    self.displayLink.frameInterval = frameInterval;
}

- (void)setImagePaths:(NSArray *)imagePaths {
    _imagePaths = imagePaths;
    
    [self updatePlayState];
}

- (void)onDisplayLinkFired:(CADisplayLink *)displayLink {
    NSAssert(self.imagePaths.count > 0, @"No images");
    
    self.frameIndex++;
    if (self.frameIndex >= self.imagePaths.count) {
        self.frameIndex = 0;
    }

    NSString *imagePath = self.imagePaths[self.frameIndex];
    self.imageView.image = [UIImage imageWithContentsOfFile:imagePath];
}

- (void)setAnimated:(BOOL)animated {
    _animated = animated;
    
    [self updatePlayState];
}

- (void)updatePlayState {
    self.displayLink.paused = !self.animated || self.imagePaths.count == 0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = self.bounds;
}

@end
