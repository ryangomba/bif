@import UIKit;

#import "BGBurstGroup.h"
#import "BGFinalizedBurst.h"

@class BGShareViewController;
@protocol BGShareViewControllerDelegate <NSObject>

- (void)shareViewControllerWantsDismissal:(BGShareViewController *)controller;

@end

@interface BGShareViewController : UIViewController

@property (nonatomic, weak) id<BGShareViewControllerDelegate> delegate;

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup finalizedBurst:(BGFinalizedBurst *)finalizedBurst;

@end
