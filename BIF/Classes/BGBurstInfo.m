// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstInfo.h"

static NSString * const kBurstIdentifierKey = @"burstIdentifier";
static NSString * const kFramesPerSecondKey = @"framesPerSecond";
static NSString * const kStartFrameIdentifierKey = @"startFrameIdentifierKey";
static NSString * const kEndFrameIdentifierKey = @"endFrameIdentifierKey";
static NSString * const kLoopModeKey = @"loopModeKey";
static NSString * const kTextKey = @"textKey";
static NSString * const kTextPositionKey = @"textPositionKey";

static CGFloat const kDefaultFramesPerSecond = 12.0;

@implementation BGBurstInfo

- (instancetype)initWithBurstIdentifier:(NSString *)burstIdentifier {
    if (self = [super init]) {
        self.burstIdentifier = burstIdentifier;
        self.framesPerSecond = kDefaultFramesPerSecond;
        self.textPosition = 0.5;
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
        self.loopMode = [dictionary[kLoopModeKey] integerValue];
        
        self.text = dictionary[kTextKey];
        self.textPosition = [dictionary[kTextPositionKey] floatValue];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setValue:self.burstIdentifier forKey:kBurstIdentifierKey];
    
    [dictionary setValue:@(self.framesPerSecond) forKey:kFramesPerSecondKey];
    [dictionary setValue:self.startFrameIdentifier forKey:kStartFrameIdentifierKey];
    [dictionary setValue:self.endFrameIdentifier forKey:kEndFrameIdentifierKey];
    [dictionary setValue:@(self.loopMode) forKey:kLoopModeKey];
    
    [dictionary setValue:self.text forKey:kTextKey];
    [dictionary setValue:@(self.textPosition) forKey:kTextPositionKey];
    
    return dictionary;
}

@end
