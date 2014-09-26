// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGFileUploader.h"

@interface BGFileUploader ()<NSURLConnectionDataDelegate>

@property (nonatomic, strong) id selfReference;

@property (nonatomic, assign) unsigned long long uploadDataLength;

@property (nonatomic, strong) NSMutableData *data;

@property (nonatomic, strong) void (^progressBlock)(CGFloat);
@property (nonatomic, strong) void (^completionBlock)(NSURL *, NSError *);

@end

@implementation BGFileUploader

- (void)uploadFileAtPath:(NSString *)filePath
                progress:(void (^)(CGFloat))progressBlock
              completion:(void (^)(NSURL *, NSError *))completionBlock {
    
    self.selfReference = self;
    
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    
    NSURL *url = [NSURL URLWithString:@"https://api.parse.com/1/files/GIF.gif"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"KuffpRMHR5h7F42uiF1V3bvwJfvIVdKm4aR1oNM7" forHTTPHeaderField:@"X-Parse-Application-Id"];
    [request setValue:@"UNXES5bw2HhG9GPb6EGeOL48mJTRTEexb4a5Uet6" forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [request setValue:@"image/gif" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:filePath]];
    
    self.uploadDataLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection start];
}


#pragma mark -
#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    
    CGFloat progress = totalBytesWritten / (double)self.uploadDataLength;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressBlock(MIN(progress, 0.95));
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completionBlock(nil, error);
        
        self.progressBlock = nil;
        self.completionBlock = nil;
        self.selfReference = nil;
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    self.data = self.data ?: [NSMutableData data];
    
    [self.data appendBytes:data.bytes length:data.length];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSURL *url;
    NSError *error;
    
    NSError *parsingError = nil;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&parsingError];
    if (parsingError) {
        error = parsingError;
    } else {
        url = [NSURL URLWithString:responseDict[@"url"]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completionBlock(url, error);
        
        self.progressBlock = nil;
        self.completionBlock = nil;
        self.selfReference = nil;
    });
}

@end
