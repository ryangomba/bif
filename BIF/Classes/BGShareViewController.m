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

typedef NS_ENUM(NSInteger, ShareSection) {
    ShareSectionCancel,
    ShareSectionServices,
    ShareSectionCount,
};

typedef NS_ENUM(NSInteger, ShareService) {
    ShareServiceCopyLink,
    ShareServiceMessage,
    ShareServiceTwitter,
    ShareServiceCount,
    ShareServiceFacebook,
    ShareServiceEmail,
    ShareServiceWhatsapp,
    ShareServiceTumblr,
    ShareServiceVine,
};

static NSString * kCellReuseID = @"cell";

@interface BGShareViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate> {
    // TEMP
    NSMutableArray *_shownAccounts;
}

@property (nonatomic, strong) BGBurstGroup *burstGroup;
@property (nonatomic, strong) BGFinalizedBurst *finalizedBurst;
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign) BOOL hasBeenMadeVisibleOnce;

@end

@implementation BGShareViewController

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup finalizedBurst:(BGFinalizedBurst *)finalizedBurst {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.burstGroup = burstGroup;
        self.finalizedBurst = finalizedBurst;
        
        [self.finalizedBurst renderWithCompletion:^(NSString *filePath) {
            self.filePath = filePath;
        }];
        
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
    
    if (!self.hasBeenMadeVisibleOnce) {
        self.hasBeenMadeVisibleOnce = YES;
        [self animateShareOptionsVisible:YES];
    }
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
#pragma mark Helpers

- (CGFloat)sectionSpacing {
    CGFloat cancelSectionHeight = kCellHeight;
    CGFloat serviceSectionHeight = ShareServiceCount * kCellHeight + (ShareSectionCount - 1) * kCellHeight;
    return self.view.bounds.size.height - 2 * kVerticalInset - cancelSectionHeight - serviceSectionHeight;
}

- (NSIndexPath *)indexPathForShareService:(ShareService)shareService {
    return [NSIndexPath indexPathForItem:shareService inSection:ShareSectionServices];
}

- (void)finish {
    [self.delegate shareViewControllerWantsDismissal:self];
    [self animateShareOptionsVisible:NO];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return ShareSectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case ShareSectionCancel:
            return 1;
        case ShareSectionServices:
            return ShareServiceCount;
        default:
            return 0;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return kCellSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (section == ShareSectionCancel) {
        return UIEdgeInsetsMake(0.0, 0.0, [self sectionSpacing], 0.0);
    }
    return UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(kCellWidth, kCellHeight);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ShareSectionCancel:
            return [self collectionView:collectionView cancelCellAtIndexPath:indexPath];
        case ShareSectionServices:
            return [self collectionView:collectionView cellForShareServiceAtIndexPath:indexPath];
        default:
            return nil;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cancelCellAtIndexPath:(NSIndexPath *)indexPath {
    BGShareCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];
    [cell setDefaultTitle:nil workingTitle:nil successTitle:nil imageName:@"xGlyph"];
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForShareServiceAtIndexPath:(NSIndexPath *)indexPath {
    BGShareCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case ShareServiceCopyLink:
            [cell setDefaultTitle:@"Copy Link" workingTitle:@"Copying Link..." successTitle:@"Link Copied!" imageName:@"linkGlyph"];
            break;
        case ShareServiceMessage:
            [cell setDefaultTitle:@"Message" workingTitle:nil successTitle:nil imageName:@"messageGlyph"];
            break;
        case ShareServiceTwitter:
            [cell setDefaultTitle:@"Twitter" workingTitle:@"Tweeting..." successTitle:@"Tweet sent!" imageName:@"twitterGlyph"];
            break;
        case ShareServiceFacebook:
            [cell setDefaultTitle:@"Facebook" workingTitle:nil successTitle:nil imageName:@"facebookGlyph"];
            break;
        case ShareServiceEmail:
            [cell setDefaultTitle:@"Email" workingTitle:nil successTitle:nil imageName:@"emailGlyph"];
            break;
        case ShareServiceWhatsapp:
            [cell setDefaultTitle:@"WhatsApp" workingTitle:nil successTitle:nil imageName:@"whatsappGlyph"];
            break;
        case ShareServiceTumblr:
            [cell setDefaultTitle:@"Tumblr" workingTitle:nil successTitle:nil imageName:@"tumblrGlyph"];
            break;
        case ShareServiceVine:
            [cell setDefaultTitle:@"Vine" workingTitle:nil successTitle:nil imageName:@"vineGlyph"];
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
    
    if (indexPath.section == ShareSectionCancel) {
        [self finish];
        return;
    }
    
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

        case ShareServiceEmail: {
            // TODO
        } break;
            
        case ShareServiceFacebook: {
            // TODO
        } break;
            
        case ShareServiceWhatsapp: {
            // TODO
        } break;
            
        case ShareServiceTumblr: {
            // TODO
        } break;
            
        case ShareServiceVine: {
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
    CGFloat endScale = visible ? 1.0 : 0.8;
    CGFloat duration = visible ? 1.5 : 0.75;
    
    CGFloat delay = 0.0;
    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
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
    NSIndexPath *cellIndexPath = [self indexPathForShareService:ShareServiceCopyLink];
    BGShareCell *shareCell = (id)[self.collectionView cellForItemAtIndexPath:cellIndexPath];
    shareCell.shareState = BGShareCellStateSharing;
    
    [BGFileUploader uploadFileAtPath:filePath completion:^(NSURL *url, NSError *error) {
        if (url) {
            shareCell.shareState = BGShareCellStateShared;
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.URL = url;
            
        } else {
            shareCell.shareState = BGShareCellStateNormal;
            [[[UIAlertView alloc] initWithTitle:@"Error Uploading GIF"
                                        message:@"Please check your internet connection and try again"
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
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
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
    
    NSIndexPath *cellIndexPath = [self indexPathForShareService:ShareServiceTwitter];
    BGShareCell *shareCell = (id)[self.collectionView cellForItemAtIndexPath:cellIndexPath];
    shareCell.shareState = BGShareCellStateSharing;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (!error && responseData) {
            NSError *parseError = nil;
            id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];
            if (!json) {
                error = [NSError errorWithDomain:@"com.ryangomba.bif" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Error parsing Twitter's response"}];
                NSLog(@"Parse Error: %@", parseError);
            } else {
                NSArray *twitterError = [json[@"errors"] firstObject];
                if (twitterError) {
                    NSString *errorDescription = [NSString stringWithFormat:@"Twitter error: %@", twitterError];
                    error = [NSError errorWithDomain:@"com.ryangomba.bif" code:0 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                    NSLog(@"API Error: %@", json);
                } else {
                    NSLog(@"Tweet sent");
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                shareCell.shareState = BGShareCellStateNormal;
                [[[UIAlertView alloc] initWithTitle:@"Error Posting Tweet"
                                            message:error.localizedDescription
                                           delegate:nil
                                  cancelButtonTitle:@"Dismiss"
                                  otherButtonTitles:nil] show];
            } else {
                shareCell.shareState = BGShareCellStateShared;
            }
        });
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
