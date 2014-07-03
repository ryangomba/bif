//
//  BGShareViewController.h
//  BIF
//
//  Created by Ryan Gomba on 7/3/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BGBurstGroup.h"

@interface BGShareViewController : UIViewController

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup filePath:(NSString *)filePath;

@end
