// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstListViewController.h"

#import "BIFHelpers.h"
#import "BGBurstGroup.h"
#import "BGBurstGroupRangePicker.h"
#import "BGBurstGroupCell.h"
#import "BGBurstGroupFetcher.h"
#import "BGBurstPreviewViewController.h"
#import "BGEditTransition.h"

static NSString * const kCellReuseID = @"cell";

@interface BGBurstListViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BGBurstGroupFetcherDelegate, BGBurstPreviewViewControllerDelegate>

@property (nonatomic, strong) BGBurstGroupFetcher *burstFetcher;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *burstGroups;

@property (nonatomic, strong) BGEditTransition *editTransition;

@property (nonatomic, strong) UINavigationBar *navigationBar;

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
    
    self.navigationBar.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 64.0); // hack hardcoded
    [self.view addSubview:self.navigationBar];
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
    
    UIEdgeInsets collectionViewInsets = UIEdgeInsetsMake(self.navigationBar.bounds.size.height, 0.0, 0.0, 0.0);
    self.collectionView.frame = UIEdgeInsetsInsetRect(self.view.bounds, collectionViewInsets);
    [self.view addSubview:self.collectionView];

    [self.burstFetcher fetchBurstGroups];
}


#pragma mark -
#pragma mark Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


#pragma mark -
#pragma mark Properties

- (UINavigationBar *)navigationBar {
    if (!_navigationBar) {
        _navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
        _navigationBar.barTintColor = HEX_COLOR(0xf63440);
        _navigationBar.tintColor = [UIColor whiteColor];
        _navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
        _navigationBar.translucent = NO;
    }
    return _navigationBar;
}

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
#pragma mark IndexPath Helpers

- (BGBurstGroup *)burstGroupAtIndexPath:(NSIndexPath *)indexPath {
    return self.burstGroups[indexPath.row];
}

- (NSIndexPath *)indexPathForBurstGroup:(BGBurstGroup *)burstGroup {
    NSUInteger burstGroupIndex = [self.burstGroups indexOfObject:burstGroup];
    NSAssert(burstGroupIndex != NSNotFound, @"Burst group not represented in list");
    return [NSIndexPath indexPathForRow:burstGroupIndex inSection:0];
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

    BGBurstGroup *burstGroup = [self burstGroupAtIndexPath:indexPath];
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
    BGBurstGroup *burstGroup = [self burstGroupAtIndexPath:indexPath];
    BGBurstPreviewViewController *vc = [[BGBurstPreviewViewController alloc] initWithBurstGroup:burstGroup];
    [vc view]; // HACK force load
    vc.delegate = self;
    
    self.editTransition = [[BGEditTransition alloc] initWithBurstGroup:burstGroup fromController:self toController:vc];
    vc.transitioningDelegate = self.editTransition;
    
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark -
#pragma mark BGBurstPreviewViewControllerDelegate

- (void)burstPreviewViewControllerWantsDismissal:(BGBurstPreviewViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark BGEditTransitionListController

- (CGRect)rectForRangePickerViewForBurstGroup:(BGBurstGroup *)burstGroup {
    NSIndexPath *indexPath = [self indexPathForBurstGroup:burstGroup];
    CGRect cellFrame = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath].frame;
    return [self.collectionView convertRect:cellFrame toView:self.view];
}

- (BGBurstGroupRangePicker *)stealRangePickerViewForBurstGroup:(BGBurstGroup *)burstGroup {
    NSIndexPath *indexPath = [self indexPathForBurstGroup:burstGroup];
    BGBurstGroupCell *cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
    return [cell stealRangePickerView];
}

- (void)returnRangePickerView:(BGBurstGroupRangePicker *)rangePickerView forBurstGroup:(BGBurstGroup *)burstGroup {
    NSIndexPath *indexPath = [self indexPathForBurstGroup:burstGroup];
    BGBurstGroupCell *cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell returnRangePickerView:rangePickerView];
}

@end
