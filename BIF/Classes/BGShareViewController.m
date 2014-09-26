// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGShareViewController.h"

#import "BGProgressHUD.h"
#import "BGFileUploader.h"
#import "BGShareCell.h"

static CGFloat const kCellWidth = 260.0;
static CGFloat const kCellHeight = 50.0;
static CGFloat const kCellSpacing = 25.0;
static CGFloat const kVerticalInset = 100.0;

// TODO move
@import MessageUI;
@import Accounts;
@import Social;

typedef NS_ENUM(NSInteger, ShareService) {
    ShareServiceCancel,
    ShareServiceCopyLink,
    ShareServiceMessage,
    ShareServiceTwitter,
    ShareServiceCount,
    ShareServiceFacebook,
    ShareServiceVine,
    ShareServiceTumblr,
};

static NSString * kCellReuseID = @"cell";

@interface BGShareViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate> {
    // TEMP
    NSMutableArray *_shownAccounts;
}

@property (nonatomic, strong) BGBurstGroup *burstGroup;
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) UICollectionView *collectionView;
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
    
    self.view.backgroundColor = [UIColor clearColor];
    
    CGFloat horizontalInset = (self.view.bounds.size.width - kCellWidth) / 2;
    self.collectionView.contentInset = UIEdgeInsetsMake(kVerticalInset, horizontalInset, 0.0, horizontalInset);
    self.collectionView.frame = self.view.bounds;
    [self.view addSubview:self.collectionView];
    
    // warm it up
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    NSLog(@"Warmed %@", controller.class);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self animateShareOptionsVisible:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self animateShareOptionsVisible:NO];
}


#pragma mark -
#pragma mark Status Bar

- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark -
#pragma mark Properties

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        [_collectionView registerClass:[BGShareCell class] forCellWithReuseIdentifier:kCellReuseID];
    }
    return _collectionView;
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return ShareServiceCount;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return kCellSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(kCellWidth, kCellHeight);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BGShareCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case ShareServiceCancel:
            cell.textLabel.text = @"Cancel";
            break;
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:collectionView.indexPathsForSelectedItems.firstObject animated:YES];
    
    switch (indexPath.row) {
        case ShareServiceCancel: {
            [self.delegate shareViewControllerWantsDismissal:self];
        } break;
            
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
#pragma mark Animation

- (void)animateShareOptionsVisible:(BOOL)visible {
    [self.collectionView layoutIfNeeded];
    
    CGFloat startScale = visible ? 0.8 : 1.0;
    CGFloat startAlpha = visible ? 0.0 : 1.0;
    CGFloat endAlpha = visible ? 1.0 : 0.0;
    CGFloat endScale = visible ? 1.0 : 0.05;
    CGFloat duration = visible ? 1.5 : 0.75;
    
    NSArray *cells = self.collectionView.visibleCells;
    if (!visible) {
        cells = [cells reverseObjectEnumerator].allObjects;
    }
    
    CGFloat delay = 0.0;
    for (UICollectionViewCell *cell in cells) {
        cell.transform = CGAffineTransformMakeScale(startScale, startScale);
        cell.alpha = startAlpha;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
                cell.transform = CGAffineTransformMakeScale(endScale, endScale);
                cell.alpha = endAlpha;
            } completion:nil];
        });
        delay += 0.1;
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
            
//            [[UIApplication sharedApplication] openURL:url];
            
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
