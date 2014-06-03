//
//  CHBurstGroup.h
//  Photos
//
//  Created by Ryan Gomba on 6/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BGBurstInfo.h"

@interface BGBurstGroup : NSObject

@property (nonatomic, strong) NSString *burstIdentifier;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, readonly) NSRange range;

@property (nonatomic, strong) BGBurstInfo *burstInfo;

@end
