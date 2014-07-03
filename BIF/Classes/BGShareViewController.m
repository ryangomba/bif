//
//  BGShareViewController.m
//  BIF
//
//  Created by Ryan Gomba on 7/3/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "BGShareViewController.h"

#import "BGProgressHUD.h"
#import "BGFileUploader.h"

typedef NS_ENUM(NSInteger, ShareService) {
    ShareServiceCopyLink,
    ShareServiceMessage,
    ShareServiceTwitter,
    ShareServiceFacebook,
    ShareServiceVine,
    ShareServiceTumblr,
    ShareServiceCount,
};

static NSString * kCellReuseID = @"cell";

@interface BGShareViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) BGBurstGroup *burstGroup;
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) BGProgressHUD *progressHUD; // TEMP

@end

@implementation BGShareViewController

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup filePath:(NSString *)filePath {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.burstGroup = burstGroup;
        self.filePath = filePath;
        
        self.title = @"Share";
    }
    return self;
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.frame = self.view.bounds;
    [self.view addSubview:self.tableView];
}


#pragma mark -
#pragma mark Properties

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellReuseID];
    }
    return _tableView;
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ShareServiceCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseID forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case ShareServiceCopyLink:
            cell.textLabel.text = @"Copy Link";
            break;
        case ShareServiceMessage:
            cell.textLabel.text = @"Message";
            break;
        case ShareServiceTwitter:
            cell.textLabel.text = @"Twitter";
            break;
        case ShareServiceFacebook:
            cell.textLabel.text = @"Facebook";
            break;
        case ShareServiceVine:
            cell.textLabel.text = @"Vine";
            break;
        case ShareServiceTumblr:
            cell.textLabel.text = @"Tumblr";
            break;
        default:
            break;
    }
    
    return cell;
}


#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
    
    switch (indexPath.row) {
        case ShareServiceCopyLink: {
            [self uploadGIF];
        } break;
            
        case ShareServiceMessage: {
            // TODO
        } break;
            
        case ShareServiceTwitter: {
            // TODO
        } break;
            
        case ShareServiceFacebook: {
            // TODO
        } break;
            
        case ShareServiceVine: {
            // TODO
        } break;
            
        case ShareServiceTumblr: {
            // TODO
        } break;
            
        default:
            break;
    }
}


#pragma mark -
#pragma mark Private

- (void)uploadGIF {
    self.progressHUD = [[BGProgressHUD alloc] init];
    self.progressHUD.center = self.view.center;
    self.progressHUD.text = @"Uploading GIF";
    [self.view addSubview:self.progressHUD];
    self.view.userInteractionEnabled = NO;
    
    [BGFileUploader uploadFileAtPath:self.filePath completion:^(NSURL *url, NSError *error) {
        [self.progressHUD removeFromSuperview];
        self.view.userInteractionEnabled = YES;
        
        if (url) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.URL = url;
            
            [[[UIAlertView alloc] initWithTitle:@"GIF Created!"
                                        message:@"A URL has been copied to your clipboard."
                                       delegate:nil
                              cancelButtonTitle:@"Sweet"
                              otherButtonTitles:nil] show];
            
            [[UIApplication sharedApplication] openURL:url];
            
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:error.localizedDescription
                                       delegate:nil
                              cancelButtonTitle:@"Dismiss"
                              otherButtonTitles:nil] show];
        }
    }];
}

@end
