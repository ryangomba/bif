// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGFinalizedBurst.h"

#import "BGGIFMaker.h"

@interface BGFinalizedBurst ()

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, assign) CGFloat outputSize;
@property (nonatomic, assign) CGFloat frameDuration;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CGRect textRect;
@property (nonatomic, strong) NSDictionary *textAttributes;

@end

@implementation BGFinalizedBurst

- (instancetype)initWithImages:(NSArray *)images
                      cropRect:(CGRect)cropRect
                    outputSize:(CGFloat)outputSize
                 frameDuration:(CGFloat)frameDuration
                          text:(NSString *)text
                      textRect:(CGRect)textRect
                textAttributes:(NSDictionary *)textAttributes {
    
    if (self = [super init]) {
        self.images = images;
        self.cropRect = cropRect;
        self.outputSize = outputSize;
        self.frameDuration = frameDuration;
        self.text = text;
        self.textRect = textRect;
        self.textAttributes = textAttributes;
    }
    return self;
}

- (void)renderWithCompletion:(void (^)(NSString *))completion {
    [BGGIFMaker makeGIFWithImages:self.images
                         cropRect:self.cropRect
                       outputSize:self.outputSize
                    frameDuration:self.frameDuration
                             text:self.text
                         textRect:self.textRect
                   textAttributes:self.textAttributes
                       completion:completion];
}

@end
