//
//  BGDatabase.h
//  BurstGIF
//
//  Created by Ryan Gomba on 6/8/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BGBurstInfo.h"

@interface BGDatabase : NSObject

+ (BGBurstInfo *)burstInfoForBurstIdentifier:(NSString *)burstIdentifier;
+ (void)saveBurstInfo:(BGBurstInfo *)burstInfo;

@end
