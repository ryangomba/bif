//
//  BGBurstInfo.m
//  BurstGIF
//
//  Created by Ryan Gomba on 6/8/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGBurstInfo.h"

static NSString * const kBurstIdentifierKey = @"burstIdentifier";
static NSString * const kFramesPerSecondKey = @"framesPerSecond";
static NSString * const kStartFrameIdentifierKey = @"startFrameIdentifierKey";
static NSString * const kEndFrameIdentifierKey = @"endFrameIdentifierKey";

static CGFloat const kDefaultFramesPerSecond = 12.0;

@implementation BGBurstInfo

- (instancetype)initWithBurstIdentifier:(NSString *)burstIdentifier {
    if (self = [super init]) {
        self.burstIdentifier = burstIdentifier;
        self.framesPerSecond = kDefaultFramesPerSecond;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.burstIdentifier = dictionary[kBurstIdentifierKey];
        
        NSNumber *framesPerSecondValue = dictionary[kFramesPerSecondKey];
        self.framesPerSecond = [framesPerSecondValue floatValue] ?: kDefaultFramesPerSecond;
        
        self.startFrameIdentifier = dictionary[kStartFrameIdentifierKey];
        self.endFrameIdentifier = dictionary[kEndFrameIdentifierKey];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:self.burstIdentifier forKey:kBurstIdentifierKey];
    [dictionary setValue:@(self.framesPerSecond) forKey:kFramesPerSecondKey];
    [dictionary setValue:self.startFrameIdentifier forKey:kStartFrameIdentifierKey];
    [dictionary setValue:self.endFrameIdentifier forKey:kEndFrameIdentifierKey];
    return dictionary;
}

@end
