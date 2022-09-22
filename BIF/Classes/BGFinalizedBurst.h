@import Foundation;

@interface BGFinalizedBurst : NSObject

- (instancetype)initWithPhotos:(NSArray *)photos
                      cropRect:(CGRect)cropRect
                    outputSize:(CGFloat)outputSize
                 frameDuration:(CGFloat)frameDuration
                  textElements:(NSArray *)textElements;

- (void)renderWithCompletion:(void (^)(NSString *filePath))completion;

@end
