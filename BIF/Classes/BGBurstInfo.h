//
//  BGBurstInfo.h
//  BurstGIF
//
//  Created by Ryan Gomba on 6/8/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

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

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) CGFloat textPosition;

- (instancetype)initWithBurstIdentifier:(NSString *)burstIdentifier;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
