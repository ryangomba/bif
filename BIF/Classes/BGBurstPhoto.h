@import Foundation;

@interface BGBurstPhoto : NSObject<NSCoding>

@property NSString *localIdentifier;
@property NSDate *creationDate;
@property CGFloat aspectRatio;
@property NSString *thumbnailFilePath;
@property NSString *fullscreenFilePath;

@end
