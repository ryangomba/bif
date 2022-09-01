// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGAnimatedImageView.h"

@interface BGAnimatedImageView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign, readwrite) NSInteger frameIndex;

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
    self.displayLink.preferredFramesPerSecond = frameInterval;
}

- (void)setImagePaths:(NSArray *)imagePaths {
    _imagePaths = imagePaths;
    
    [self showImageAtIndex:0];
    [self updatePlayState];
}

- (void)onDisplayLinkFired:(CADisplayLink *)displayLink {
    NSAssert(self.imagePaths.count > 0, @"No images");
    
    NSInteger nextFrameIndex = self.frameIndex + 1;
    if (nextFrameIndex >= self.imagePaths.count) {
        nextFrameIndex = 0;
    };
    [self showImageAtIndex:nextFrameIndex];
}

- (void)showImageAtIndex:(NSInteger)frameIndex {
    self.frameIndex = frameIndex;
    NSString *imagePath = self.imagePaths[self.frameIndex];
    self.imageView.image = [UIImage imageWithContentsOfFile:imagePath];
}

- (void)setAnimated:(BOOL)animated {
    _animated = animated;
    
    [self updatePlayState];
}

- (void)updatePlayState {
    BOOL play = self.animated && self.imagePaths.count > 0;
    self.displayLink.paused = !play;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = self.bounds;
}

@end
