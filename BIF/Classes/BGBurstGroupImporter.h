@import Foundation;

@interface BGBurstGroupImporter : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *importQueue;

- (void)importCameraBursts;

@end
