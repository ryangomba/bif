// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGFileUploader : NSObject

+ (void)uploadFileAtPath:(NSString *)filePath
                progress:(void (^)(CGFloat))progressBlock
              completion:(void(^)(NSURL *url, NSError *error))completionBlock;

@end
