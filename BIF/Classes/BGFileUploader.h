// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGFileUploader : NSObject

+ (void)uploadFileAtPath:(NSString *)filePath completion:(void(^)(NSURL *url, NSError *error))completion;

@end
