// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstListViewController.h"

#import "BGBurstGroupFetcher.h"
#import "BGBurstGroupCell.h"
#import "BGBurstPreviewViewController.h"
#import "BIFHelpers.h"
#import "BGEditTransition.h"

static NSString * const kCellReuseID = @"cell";

@interface BGBurstListViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BGBurstGroupFetcherDelegate, BGBurstPreviewViewControllerDelegate>

@property (nonatomic, strong) BGBurstGroupFetcher *burstFetcher;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *burstGroups;

@property (nonatomic, strong) BGEditTransition *editTransition;

@end


@implementation BGBurstListViewController

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.navigationItem.title = @"Choose a Burst";
    }
    return self;
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = kBGBackgroundColor;
    
    self.collectionView.frame = self.view.bounds;
    [self.view addSubview:self.collectionView];

    [self.burstFetcher fetchBurstGroups];
}


#pragma mark -
#pragma mark Properties

- (BGBurstGroupFetcher *)burstFetcher {
    if (!_burstFetcher) {
        _burstFetcher = [[BGBurstGroupFetcher alloc] init];
        _burstFetcher.delegate = self;
    }
    return _burstFetcher;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        [_collectionView registerClass:[BGBurstGroupCell class] forCellWithReuseIdentifier:kCellReuseID];
    }
    return _collectionView;
}


#pragma mark -
#pragma mark BGBurstGroupFetcherDelegate

- (void)burstGroupFetcher:(BGBurstGroupFetcher *)fetcher didFetchBurstGroups:(NSArray *)burstGroups {
    self.burstGroups = burstGroups;
    
    [self.collectionView reloadData];
}


#pragma mark -
#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.burstGroups.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BGBurstGroupCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];

    BGBurstGroup *burstGroup = self.burstGroups[indexPath.row];
    cell.burstGroup = burstGroup;
    
    return cell;
}


#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    
    return UIEdgeInsetsMake(kBGDefaultPadding, kBGDefaultPadding, kBGDefaultPadding, kBGDefaultPadding);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {

    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    
    return kBGDefaultPadding;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat elementWidth = collectionView.bounds.size.width - 2 * kBGDefaultPadding;
    return CGSizeMake(elementWidth, 60.0);
}


#pragma mark -
#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    BGBurstGroup *burstGroup = self.burstGroups[indexPath.row];
    BGBurstPreviewViewController *vc = [[BGBurstPreviewViewController alloc] initWithBurstGroup:burstGroup];
    vc.delegate = self;
    
    self.editTransition = [[BGEditTransition alloc] init];
    vc.transitioningDelegate = self.editTransition;
    
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark -
#pragma mark BGBurstPreviewViewControllerDelegate

- (void)burstPreviewViewControllerWantsDismissal:(BGBurstPreviewViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
