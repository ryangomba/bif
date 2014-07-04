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

// TODO move
#import <MessageUI/MessageUI.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

typedef NS_ENUM(NSInteger, ShareService) {
    ShareServiceCopyLink,
    ShareServiceMessage,
    ShareServiceTwitter,
    ShareServiceCount,
    ShareServiceFacebook,
    ShareServiceVine,
    ShareServiceTumblr,
};

static NSString * kCellReuseID = @"cell";

@interface BGShareViewController ()<UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate> {
    // TEMP
    NSMutableArray *_shownAccounts;
}

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
    
    // warm it up
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    NSLog(@"Warmed %@", controller.class);
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
            [self uploadGIFAtPath:self.filePath];
        } break;
            
        case ShareServiceMessage: {
            [self messageGIFAtPath:self.filePath];
        } break;
            
        case ShareServiceTwitter: {
            [self tweetGIFAtPath:self.filePath];
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

- (void)uploadGIFAtPath:(NSString *)filePath {
    self.progressHUD = [[BGProgressHUD alloc] init];
    self.progressHUD.center = self.view.center;
    self.progressHUD.text = @"Uploading GIF";
    [self.view addSubview:self.progressHUD];
    self.view.userInteractionEnabled = NO;
    
    [BGFileUploader uploadFileAtPath:filePath completion:^(NSURL *url, NSError *error) {
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

- (void)messageGIFAtPath:(NSString *)filePath {
    if ([MFMessageComposeViewController canSendAttachments] && [MFMessageComposeViewController isSupportedAttachmentUTI:@"image/gif"]) {
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        controller.messageComposeDelegate = self;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
        BOOL addedGIF = [controller addAttachmentURL:fileURL withAlternateFilename:nil];
        if (addedGIF) {
            [self presentViewController:controller animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Couldn't attach GIF"
                                       delegate:nil
                              cancelButtonTitle:@"Dismiss"
                              otherButtonTitles:nil] show];
        }
        
    } else {
        // TODO handle error? don't show in list? use link?
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Message attachments not supported"
                                   delegate:nil
                          cancelButtonTitle:@"Dismiss"
                          otherButtonTitles:nil] show];
    }
}

- (void)tweetGIFAtPath:(NSString *)filePath {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    if ([accountType accessGranted]) {
        [self showListOfTwitterAccountsFromStore:accountStore];
        
    } else {
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
            if (granted) {
                [self showListOfTwitterAccountsFromStore:accountStore];
                
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:@"Cannot link account without permission"
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil] show];
            }
        }];
    }
}


#pragma mark -
#pragma mark Twitter

- (void)showListOfTwitterAccountsFromStore:(ACAccountStore *)accountStore {
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *twitterAccounts = [accountStore accountsWithAccountType:accountType];
    
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:@"Choose Account to Use"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                           destructiveButtonTitle:nil
                                                otherButtonTitles:nil];
    
    NSMutableArray *shownAccounts = [NSMutableArray array];
    
    for (ACAccount *oneAccount in twitterAccounts) {
        [actions addButtonWithTitle:oneAccount.username];
        [shownAccounts addObject:oneAccount];
    }
    
    _shownAccounts = [shownAccounts copy];
    
    [actions showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    ACAccount *account = _shownAccounts[buttonIndex - 1];
    
    NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"];
    
    NSDictionary *parameters = @{@"status": @"Testing 123"};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:URL
                                               parameters:parameters];
    
    request.account = account;
    
    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:self.filePath];
    [request addMultipartData:imageData withName:@"media[]" type:@"image/gif" filename:@"image.gif"];
    
    self.progressHUD = [[BGProgressHUD alloc] init];
    self.progressHUD.center = self.view.center;
    self.progressHUD.text = @"Tweeting GIF";
    [self.view addSubview:self.progressHUD];
    self.view.userInteractionEnabled = NO;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD removeFromSuperview];
            self.view.userInteractionEnabled = YES;
        });
        
        if (responseData) {
            NSError *parseError = nil;
            id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];
            if (!json) {
                NSLog(@"Parse Error: %@", parseError);
            } else {
                NSLog(@"%@", json);
            }
            
        } else {
            NSLog(@"Request Error: %@", [error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:error.localizedDescription
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil] show];
            });
        }
    }];
}


#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {

    // TODO do something with controller.recipients for easy re-sending?
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (result == MessageComposeResultFailed) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Couldn't send message"
                                   delegate:nil
                          cancelButtonTitle:@"Dismiss"
                          otherButtonTitles:nil] show];
    }
}

@end
