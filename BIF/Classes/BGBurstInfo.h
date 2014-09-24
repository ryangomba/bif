// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@import CoreGraphics;

typedef NS_ENUM(NSInteger, LoopMode) {
    LoopModeLoop,
    LoopModeReverse,
};

@interface BGBurstInfo : NSObject

@property (nonatomic, copy) NSString *burstIdentifier;
@property (nonatomic, assign) CGFloat framesPerSecond;
@property (nonatomic, copy) NSString *startFrameIdentifier;
@property (nonatomic, copy) NSString *endFrameIdentifier;
@property (nonatomic, assign) LoopMode loopMode;
@property (nonatomic, assign) CGRect cropInfo;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) CGFloat textPosition;

- (instancetype)initWithBurstIdentifier:(NSString *)burstIdentifier;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
