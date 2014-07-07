// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGFileUploader.h"

@implementation BGFileUploader

+ (void)uploadFileAtPath:(NSString *)filePath completion:(void (^)(NSURL *, NSError *))completion {
    NSURL *url = [NSURL URLWithString:@"https://api.parse.com/1/files/GIF.gif"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"KuffpRMHR5h7F42uiF1V3bvwJfvIVdKm4aR1oNM7" forHTTPHeaderField:@"X-Parse-Application-Id"];
    [request setValue:@"UNXES5bw2HhG9GPb6EGeOL48mJTRTEexb4a5Uet6" forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [request setValue:@"image/gif" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:filePath]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         if (connectionError) {
             completion(nil, connectionError);
         } else {
             NSError *parsingError = nil;
             NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parsingError];
             if (parsingError) {
                 completion(nil, parsingError);
             } else {
                 NSURL *url = [NSURL URLWithString:responseDict[@"url"]];
                 completion(url, nil);
             }
         }
     }];
}

@end
