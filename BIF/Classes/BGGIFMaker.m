// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGGIFMaker.h"

@import ImageIO;
@import MobileCoreServices;

#import "UIImage+Resize.h"

@implementation BGGIFMaker

+ (void)makeGIFWithImages:(NSArray *)images
                 cropRect:(CGRect)cropRect
               outputSize:(CGFloat)outputSize
            frameDuration:(CGFloat)frameDuration
             textElements:(NSArray *)textElements
               completion:(void (^)(NSString *))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *filePath = [self doMakeGIFWithImages:images
                                              cropRect:cropRect
                                            outputSize:outputSize
                                         frameDuration:frameDuration
                                          textElements:textElements];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(filePath);
        });
    });
}

+ (NSString *)doMakeGIFWithImages:(NSArray *)images
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
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (UIImage *image in images) {
        @autoreleasepool {
            CGSize contextSize = CGSizeMake(outputSize, outputSize);
            UIGraphicsBeginImageContextWithOptions(contextSize, NO, 1.0);

            // draw image
            UIImage *croppedImage = [image croppedImage:cropRect];
            UIImage *resizedImage = [croppedImage squareThumbnailImageOfSize:outputSize];
            [resizedImage drawAtPoint:CGPointZero];
            
            // draw text
            for (BGTextElement *textElement in textElements) {
                // TEMP weak
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
