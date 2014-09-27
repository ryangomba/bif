// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGEntryViewController.h"

#import "BGBurstListViewController.h"
#import "BGEntryTransition.h"

@interface BGEntryViewController ()

@property (nonatomic, strong) UIImageView *launchImageView;
@property (nonatomic, strong) BGEntryTransition *transition;
@property (nonatomic, assign) BOOL didSegue;

@end

@implementation BGEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.launchImageView.frame = self.view.bounds;
    [self.view addSubview:self.launchImageView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.didSegue) {
        self.didSegue = YES;
        
        BGBurstListViewController *vc = [[BGBurstListViewController alloc] initWithNibName:nil bundle:nil];
        self.transition = [[BGEntryTransition alloc] init];
        vc.transitioningDelegate = self.transition;
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIImageView *)launchImageView {
    if (!_launchImageView) {
        _launchImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _launchImageView.image = [UIImage imageNamed:@"Start"];
        _launchImageView.contentMode = UIViewContentModeCenter;
    }
    return _launchImageView;
}

@end
