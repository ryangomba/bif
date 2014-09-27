// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGFileUploader.h"

#import <AFNetworking/AFNetworking.h>

@implementation BGFileUploader

+ (void)uploadFileAtPath:(NSString *)filePath
                progress:(void (^)(CGFloat))progressBlock
              completion:(void (^)(NSURL *, NSError *))completionBlock {
    
    NSURL *url = [NSURL URLWithString:@"https://api.parse.com/1/files/GIF.gif"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"KuffpRMHR5h7F42uiF1V3bvwJfvIVdKm4aR1oNM7" forHTTPHeaderField:@"X-Parse-Application-Id"];
    [request setValue:@"UNXES5bw2HhG9GPb6EGeOL48mJTRTEexb4a5Uet6" forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [request setValue:@"image/gif" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:filePath]];
    
    double fileLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer = [[AFJSONResponseSerializer alloc] init];
    [requestOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        CGFloat progress = totalBytesWritten / fileLength;
        progressBlock(MIN(progress, 0.95));
    }];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        completionBlock([NSURL URLWithString:responseObject[@"url"]], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completionBlock(nil, error);
    }];
    [requestOperation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [requestOperation start];
}

@end
