#import "BGGIFMaker.h"

@import UIKit;
@import ImageIO;
@import MobileCoreServices;

#import <RGImage/RGImage.h>

#import "BGBurstPhoto.h"

@implementation BGGIFMaker

+ (void)makeGIFWithPhotos:(NSArray *)photos
                 cropRect:(CGRect)cropRect
               outputSize:(CGFloat)outputSize
            frameDuration:(CGFloat)frameDuration
             textElements:(NSArray *)textElements
               completion:(void (^)(NSString *))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *filePath = [self doMakeGIFWithPhotos:photos
                                              cropRect:cropRect
                                            outputSize:outputSize
                                         frameDuration:frameDuration
                                          textElements:textElements];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(filePath);
        });
    });
}

+ (NSString *)doMakeGIFWithPhotos:(NSArray *)photos
                         cropRect:(CGRect)cropRect
                       outputSize:(CGFloat)outputSize
                    frameDuration:(CGFloat)frameDuration
                     textElements:(NSArray *)textElements {
    
    NSDictionary *fileProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFLoopCount: @0,
        }
    };
    
//    const uint8_t colorTable[ 6 ] = { 0, 0, 0, 255, 255, 255 };
//    NSData *colorTableData = [ NSData dataWithBytes: colorTable length: 6 ];
    
    NSDictionary *frameProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFDelayTime: @(frameDuration),
//            (__bridge id)kCGImagePropertyColorModel: (__bridge id)kCGImagePropertyColorModelRGB,
//            (__bridge id)kCGImagePropertyGIFHasGlobalColorMap: @(NO),
//            (__bridge id)kCGImagePropertyGIFImageColorMap: colorTableData,
        }
    };
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, photos.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (BGBurstPhoto *photo in photos) {
        @autoreleasepool {
            CGSize contextSize = CGSizeMake(outputSize, outputSize);
            UIGraphicsBeginImageContextWithOptions(contextSize, NO, 1.0);

            UIImage *image = [UIImage imageWithContentsOfFile:photo.fullscreenFilePath];
            
            // draw image
            CGRect denormalizedCropRect = CGRectZero;
            denormalizedCropRect.origin.x = image.size.width * cropRect.origin.x;
            denormalizedCropRect.origin.y = image.size.height * cropRect.origin.y;
            denormalizedCropRect.size.width = image.size.width * cropRect.size.width;
            denormalizedCropRect.size.height = image.size.height * cropRect.size.height;
            UIImage *croppedImage = [image croppedImage:denormalizedCropRect];
            [croppedImage drawInRect:CGRectMake(0.0, 0.0, outputSize, outputSize)];
            
            // draw text
            for (BGTextElement *textElement in textElements) {
                CGRect textRect = textElement.textRect;
                textRect.origin.x = ceilf(textRect.origin.x * outputSize);
                textRect.origin.y = ceilf(textRect.origin.y * outputSize);
                textRect.size.width = ceilf(textRect.size.width * outputSize);
                textRect.size.height = ceilf(textRect.size.height * outputSize);
                [textElement.text drawInRect:textRect withAttributes:textElement.textAttributes];
            }
            
            UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            CGImageDestinationAddImage(destination, finalImage.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    return fileURL.path;
}

@end
