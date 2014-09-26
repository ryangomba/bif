// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGFinalizedBurst : NSObject

- (instancetype)initWithImages:(NSArray *)images
                      cropRect:(CGRect)cropRect
                    outputSize:(CGFloat)outputSize
                 frameDuration:(CGFloat)frameDuration
                          text:(NSString *)text
                      textRect:(CGRect)textRect
                textAttributes:(NSDictionary *)textAttributes;

- (void)renderWithCompletion:(void (^)(NSString *filePath))completion;

@end
