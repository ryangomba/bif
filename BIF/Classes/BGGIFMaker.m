//
//  CHGIFMaker.m
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGGIFMaker.h"

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
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
            UIImage *resizedImage = [image squareThumbnailImageOfSize:outputSize];

            // draw text
            CGSize contextSize = CGSizeMake(outputSize, outputSize);
            UIGraphicsBeginImageContextWithOptions(contextSize, NO, 0);
            [resizedImage drawAtPoint:CGPointZero];
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
