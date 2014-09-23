// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGGIFMaker : NSObject

+ (void)makeGIFWithImages:(NSArray *)images
                 cropRect:(CGRect)cropRect
               outputSize:(CGFloat)outputSize
            frameDuration:(CGFloat)frameDuration
                     text:(NSString *)text
                 textRect:(CGRect)textRect
           textAttributes:(NSDictionary *)textAttributes
               completion:(void(^)(NSString *filePath))completion;

@end
