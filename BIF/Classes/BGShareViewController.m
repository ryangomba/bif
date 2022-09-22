#import "BGShareViewController.h"

#import "BGProgressHUD.h"
#import "BGShareCell.h"

static CGFloat const kCellWidth = 260.0;
static CGFloat const kCellHeight = 50.0;
static CGFloat const kCellSpacing = 25.0;
static CGFloat const kVerticalInset = 100.0;

// TODO move
@import MessageUI;

typedef NS_ENUM(NSInteger, ShareSection) {
    ShareSectionCancel,
    ShareSectionServices,
    ShareSectionCount,
};

typedef NS_ENUM(NSInteger, ShareService) {
    ShareServiceMessage,
    ShareServiceCount,
};

static NSString * kCellReuseID = @"cell";

@interface BGShareViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate> {}

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
        case ShareServiceMessage:
            [cell setDefaultTitle:@"Message" workingTitle:nil successTitle:nil imageName:@"messageGlyph"];
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
    
    BGShareCell *cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell.sharedURL && cell.shareState == BGShareCellStateShared) {
        [[UIApplication sharedApplication] openURL:cell.sharedURL];
        return;
    }
    
    [self uploadToService:indexPath.row cell:cell];
}

- (void)uploadToService:(ShareService)service cell:(BGShareCell *)cell {
    // HACKS!!!
    
    if (cell.workingTitle && cell.shareState != BGShareCellStateSharing) {
        cell.shareState = BGShareCellStateSharing;
        cell.shareProgress = 0.05;
    }
    
    if (!self.filePath) {
        NSLog(@"Waiting for GIF to render");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadToService:service cell:cell];
        });

    } else {
        [self doUploadToService:service];
    }
}

- (void)doUploadToService:(ShareService)service {
    switch (service) {
        case ShareServiceMessage: {
            [self messageGIFAtPath:self.filePath];
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

@end
