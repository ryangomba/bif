// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGGIFMaker.h"

@import ImageIO;
@import MobileCoreServices;

#import "UIImage+Resize.h"

@implementation BGGIFMaker

+ (void)makeGIFWithImages:(NSArray *)images
               outputSize:(CGFloat)outputSize
            frameDuration:(CGFloat)frameDuration
                     text:(NSString *)text
                 textRect:(CGRect)textRect
           textAttributes:(NSDictionary *)textAttributes
               completion:(void (^)(NSString *))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *filePath = [self doMakeGIFWithImages:images
                                            outputSize:outputSize
                                         frameDuration:frameDuration
                                                  text:text
                                              textRect:textRect
                                        textAttributes:textAttributes];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(filePath);
        });
    });
}

+ (NSString *)doMakeGIFWithImages:(NSArray *)images
                       outputSize:(CGFloat)outputSize
                    frameDuration:(CGFloat)frameDuration
                             text:(NSString *)text
                         textRect:(CGRect)textRect
                   textAttributes:(NSDictionary *)textAttributes {

    // TEMP weak
    textRect.origin.x *= outputSize;
    textRect.origin.y *= outputSize;
    textRect.size.width *= outputSize;
    textRect.size.height *= outputSize;
    
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
            UIImage *resizedImage = [image squareThumbnailImageOfSize:outputSize];
            [resizedImage drawAtPoint:CGPointZero];
            
            // draw text
            [text drawInRect:textRect withAttributes:textAttributes];
            
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
