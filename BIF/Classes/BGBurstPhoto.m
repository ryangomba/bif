// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstPhoto.h"

static NSString * const kLocalIdentifierKey = @"localIdentifier";
static NSString * const kCreationDateKey = @"creationDate";
static NSString * const kAspectRatioKey = @"aspectRatio";
static NSString * const kThumbnailFilePathKey = @"thumbnailFilePath";
static NSString * const kFullscreenFilePathKey = @"fullscreenFilePath";

@implementation BGBurstPhoto

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.localIdentifier = [aDecoder decodeObjectForKey:kLocalIdentifierKey];
        self.creationDate = [aDecoder decodeObjectForKey:kCreationDateKey];
        self.aspectRatio = [[aDecoder decodeObjectForKey:kAspectRatioKey] floatValue];
        self.thumbnailFilePath = [aDecoder decodeObjectForKey:kThumbnailFilePathKey];
        self.fullscreenFilePath = [aDecoder decodeObjectForKey:kFullscreenFilePathKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.localIdentifier forKey:kLocalIdentifierKey];
    [aCoder encodeObject:self.creationDate forKey:kCreationDateKey];
    [aCoder encodeObject:@(self.aspectRatio) forKey:kAspectRatioKey];
    [aCoder encodeObject:self.thumbnailFilePath forKey:kThumbnailFilePathKey];
    [aCoder encodeObject:self.fullscreenFilePath forKey:kFullscreenFilePathKey];
}

@end
