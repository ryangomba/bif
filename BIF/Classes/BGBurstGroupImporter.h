// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGBurstGroupImporter : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *importQueue;

- (void)importCameraBursts;

@end
