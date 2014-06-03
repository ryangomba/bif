//
//  CHFileUploader.h
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BGFileUploader : NSObject

+ (void)uploadFileAtPath:(NSString *)filePath completion:(void(^)(NSURL *url, NSError *error))completion;

@end
