#import "BGTextElement.h"

@interface BGGIFMaker : NSObject

+ (void)makeGIFWithPhotos:(NSArray *)photos
                 cropRect:(CGRect)cropRect
               outputSize:(CGFloat)outputSize
            frameDuration:(CGFloat)frameDuration
             textElements:(NSArray *)textElements
               completion:(void(^)(NSString *filePath))completion;

@end
