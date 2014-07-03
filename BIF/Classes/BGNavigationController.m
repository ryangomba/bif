//
//  BGNavigationController.m
//  BIF
//
//  Created by Ryan Gomba on 7/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGNavigationController.h"

#import "BIFHelpers.h"

@implementation BGNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
//        self.navigationBarHidden = YES;
        self.navigationBar.barTintColor = HEX_COLOR(0xf63440);
        self.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationBar.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
        };
        self.navigationBar.translucent = NO;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
