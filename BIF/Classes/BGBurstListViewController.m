// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGBurstListViewController.h"

#import "BIFHelpers.h"
#import "BGBurstGroup.h"
#import "BGBurstGroupRangePicker.h"
#import "BGCollectionView.h"
#import "BGBurstGroupCell.h"
#import "BGBurstGroupImporter.h"
#import "BGBurstGroupDataSource.h"
#import "BGDataSourceUpdate.h"
#import "BGLoadingInfoView.h"
#import "BGBurstPreviewViewController.h"
#import "BGEditTransition.h"

static CGFloat const kCellHeight = 60.0;

static NSString * const kCellReuseID = @"cell";

@interface BGBurstListViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BGBurstGroupDataSourceDelegate, BGBurstPreviewViewControllerDelegate>

@property (nonatomic, strong) BGBurstGroupImporter *burstImporter;
@property (nonatomic, strong) BGBurstGroupDataSource *dataSource;

@property (nonatomic, strong) BGCollectionView *collectionView;
@property (nonatomic, strong) BGLoadingInfoView *footerView;
@property (nonatomic, strong) NSArray *burstGroups;

@property (nonatomic, strong) BGEditTransition *editTransition;

@property (nonatomic, strong) UINavigationBar *navigationBar;

@property (nonatomic, strong) NSArray *pendingBurstGroups;

@end


@implementation BGBurstListViewController

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [self.burstImporter.importQueue removeObserver:self forKeyPath:@"operationCount"];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.navigationItem.title = @"Choose a Burst";
        
        self.burstImporter = [[BGBurstGroupImporter alloc] init];
        [self.burstImporter.importQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [self.burstImporter importCameraBursts];
    }
    return self;
}


#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    NSInteger importCount = [change[NSKeyValueChangeNewKey] integerValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTitleWithImportCount:importCount];
    });
}

- (void)updateTitleWithImportCount:(NSInteger)importCount {
    if (importCount > 0) {
        NSString *title;
        if (importCount == 1) {
            title = @"Importing 1 Burst";
        } else {
            title = [NSString stringWithFormat:@"Importing %lu Bursts", importCount];
        }
        self.footerView.text = title;
        self.collectionView.footerView = self.footerView;
    } else {
        self.collectionView.footerView = nil;
    }
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
    
    self.dataSource = [[BGBurstGroupDataSource alloc] init];
    self.dataSource.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.pendingBurstGroups) {
        [self updateCollectionView];
    }
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
        _navigationBar.titleTextAttributes = @{
            NSFontAttributeName: [UIFont fontWithName:@"ProximaNovaSoft-Medium" size:18.0],
            NSForegroundColorAttributeName: [UIColor whiteColor]
        };
        _navigationBar.translucent = NO;
    }
    return _navigationBar;
}

- (BGCollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[BGCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        [_collectionView registerClass:[BGBurstGroupCell class] forCellWithReuseIdentifier:kCellReuseID];
    }
    return _collectionView;
}

- (BGLoadingInfoView *)footerView {
    if (!_footerView) {
        _footerView = [[BGLoadingInfoView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, kCellHeight)];
        _footerView.bottomInset = kBGLargePadding;
    }
    return _footerView;
}


#pragma mark -
#pragma mark BGBurstGroupFetcherDelegate

- (void)burstGroupDataSource:(BGBurstGroupDataSource *)dataSource didUpdateBurstGroups:(NSArray *)burstGroups {
    self.pendingBurstGroups = burstGroups;
    
    if (!self.presentedViewController) {
        [self updateCollectionView];
    }
}

- (void)updateCollectionView {
    if (!self.pendingBurstGroups) {
        return;
    }
    
    BGDataSourceUpdate *update = [BGDataSourceUpdate updateFromObjects:self.burstGroups toObjects:self.pendingBurstGroups];
    
    NSMutableArray *deletedIndexPaths = [NSMutableArray array];
    [update.deletedIndexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
        [deletedIndexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }];
    
    NSMutableArray *insertedIndexPaths = [NSMutableArray array];
    [update.insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
        [insertedIndexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }];
    
    [UIView setAnimationsEnabled:NO];
    [self.collectionView performBatchUpdates:^{
        self.burstGroups = update.objects;
        [self.collectionView deleteItemsAtIndexPaths:deletedIndexPaths];
        [self.collectionView insertItemsAtIndexPaths:insertedIndexPaths];
        
    } completion:^(BOOL finished) {
        [UIView setAnimationsEnabled:YES];
    }];
    
    self.pendingBurstGroups = nil;
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
    
    return UIEdgeInsetsMake(kBGLargePadding, kBGLargePadding, kBGLargePadding, kBGLargePadding);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {

    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    
    return kBGLargePadding;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat elementWidth = collectionView.bounds.size.width - 2 * kBGLargePadding;
    return CGSizeMake(elementWidth, kCellHeight);
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
