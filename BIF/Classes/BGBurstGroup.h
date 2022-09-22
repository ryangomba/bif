@import Foundation;
#import "BGLoopMode.h"
#import "BGBurstPhoto.h"

@interface BGBurstGroup : NSObject<NSCoding>

@property NSString *burstIdentifier;
@property NSDate *creationDate;

@property CGFloat framesPerSecond;
@property NSString *startFrameIdentifier;
@property NSString *endFrameIdentifier;
@property LoopMode loopMode;
@property NSString *text;
@property CGFloat textPosition;
@property CGRect cropInfo;

@property NSArray *photos;

- (NSRange)range; // TODO make this better

@end
