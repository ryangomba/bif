// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"

static NSString * const kBurstIdentifierKey = @"burstIdentifier";
static NSString * const kCreationDateKey = @"creationDate";

static NSString * const kFramesPerSecondKey = @"framesPerSecond";
static NSString * const kStartFrameIdentifierKey = @"startFrameIdentifierKey";
static NSString * const kEndFrameIdentifierKey = @"endFrameIdentifierKey";
static NSString * const kLoopModeKey = @"loopModeKey";
static NSString * const kTextKey = @"textKey";
static NSString * const kTextPositionKey = @"textPositionKey";
static NSString * const kCropInfoKey = @"cropInfoKey";

static NSString * const kPhotosKey = @"photos";

static CGFloat const kDefaultFramesPerSecond = 12.0;

@implementation BGBurstGroup

#pragma mark -
#pragma mark NSObject

- (instancetype)init {
    if (self = [super init]) {
        self.framesPerSecond = kDefaultFramesPerSecond;
    }
    return self;
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.burstIdentifier = [aDecoder decodeObjectForKey:kBurstIdentifierKey];
        self.creationDate = [aDecoder decodeObjectForKey:kCreationDateKey];
        
        self.framesPerSecond = [[aDecoder decodeObjectForKey:kFramesPerSecondKey] floatValue];
        self.startFrameIdentifier = [aDecoder decodeObjectForKey:kStartFrameIdentifierKey];
        self.endFrameIdentifier = [aDecoder decodeObjectForKey:kEndFrameIdentifierKey];
        self.loopMode = [[aDecoder decodeObjectForKey:kLoopModeKey] integerValue];
        self.text = [aDecoder decodeObjectForKey:kTextKey];
        self.textPosition = [[aDecoder decodeObjectForKey:kTextPositionKey] floatValue];
        self.cropInfo = [[aDecoder decodeObjectForKey:kCropInfoKey] CGRectValue];
        
        self.photos = [aDecoder decodeObjectForKey:kPhotosKey];
        
        NSAssert(self.photos.count > 0, @"No photos");
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.burstIdentifier forKey:kBurstIdentifierKey];
    [aCoder encodeObject:self.creationDate forKey:kCreationDateKey];
    
    [aCoder encodeObject:@(self.framesPerSecond) forKey:kFramesPerSecondKey];
    [aCoder encodeObject:self.startFrameIdentifier forKey:kStartFrameIdentifierKey];
    [aCoder encodeObject:self.endFrameIdentifier forKey:kEndFrameIdentifierKey];
    [aCoder encodeObject:@(self.loopMode) forKey:kLoopModeKey];
    [aCoder encodeObject:self.text forKey:kTextKey];
    [aCoder encodeObject:@(self.textPosition) forKey:kTextPositionKey];
    [aCoder encodeObject:[NSValue valueWithCGRect:self.cropInfo] forKey:kCropInfoKey];
    
    [aCoder encodeObject:self.photos forKey:kPhotosKey];
}


#pragma mark -
#pragma mark Public

- (NSRange)range {
    NSArray *localIdentifiers = [self.photos valueForKey:@"localIdentifier"];
    
    NSString *startID = self.startFrameIdentifier;
    NSUInteger startIndex = [localIdentifiers indexOfObject:startID];
    if (startIndex == NSNotFound) {
        startIndex = 0;
    }
    
    NSString *endID = self.endFrameIdentifier;
    NSUInteger endIndex = [localIdentifiers indexOfObject:endID];
    if (endIndex == NSNotFound) {
        endIndex = self.photos.count - 1;
    }
    
    return NSMakeRange(startIndex, endIndex - startIndex);
}

@end
