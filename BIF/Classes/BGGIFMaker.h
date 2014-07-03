//
//  CHGIFMaker.h
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BGGIFMaker : NSObject

+ (void)makeGIFWithImages:(NSArray *)images
               outputSize:(CGFloat)outputSize
            frameDuration:(CGFloat)frameDuration
                     text:(NSString *)text
                 textRect:(CGRect)textRect
           textAttributes:(NSDictionary *)textAttributes
               completion:(void(^)(NSString *filePath))completion;

@end
