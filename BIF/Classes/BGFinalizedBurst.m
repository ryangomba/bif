// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGFinalizedBurst.h"

#import "BGGIFMaker.h"

@interface BGFinalizedBurst ()

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, assign) CGFloat outputSize;
@property (nonatomic, assign) CGFloat frameDuration;
@property (nonatomic, strong) NSArray *textElements;

@end

@implementation BGFinalizedBurst

- (instancetype)initWithImages:(NSArray *)images
                      cropRect:(CGRect)cropRect
                    outputSize:(CGFloat)outputSize
                 frameDuration:(CGFloat)frameDuration
                  textElements:(NSArray *)textElements {
    
    if (self = [super init]) {
        self.images = images;
        self.cropRect = cropRect;
        self.outputSize = outputSize;
        self.frameDuration = frameDuration;
        self.textElements = textElements;
    }
    return self;
}

- (void)renderWithCompletion:(void (^)(NSString *))completion {
    [BGGIFMaker makeGIFWithImages:self.images
                         cropRect:self.cropRect
                       outputSize:self.outputSize
                    frameDuration:self.frameDuration
                     textElements:self.textElements
                       completion:completion];
}

@end
