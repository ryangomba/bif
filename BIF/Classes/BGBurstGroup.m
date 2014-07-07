// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstGroup.h"

@import Photos;

@implementation BGBurstGroup

- (instancetype)init {
    if (self = [super init]) {
        self.photos = [NSMutableArray array];
    }
    return self;
}

- (NSRange)range {
    NSArray *localIdentifiers = [self.photos valueForKey:@"localIdentifier"];
    
    NSString *startID = self.burstInfo.startFrameIdentifier;
    NSUInteger startIndex = [localIdentifiers indexOfObject:startID];
    if (startIndex == NSNotFound) {
        startIndex = 0;
    }
    
    NSString *endID = self.burstInfo.endFrameIdentifier;
    NSUInteger endIndex = [localIdentifiers indexOfObject:endID];
    if (endIndex == NSNotFound) {
        endIndex = self.photos.count - 1;
    }
    
    return NSMakeRange(startIndex, endIndex - startIndex);
}

@end
