#import "BGBurstGroup.h"

// HACK messy
#import "BGEditTransition.h"

@class BGBurstPreviewViewController;
@protocol BGBurstPreviewViewControllerDelegate <NSObject>

- (void)burstPreviewViewControllerWantsDismissal:(BGBurstPreviewViewController *)controller;

@end

@interface BGBurstPreviewViewController : UIViewController<BGEditTransitionPreviewController>

@property (nonatomic, weak) id<BGBurstPreviewViewControllerDelegate> delegate;

- (instancetype)initWithBurstGroup:(BGBurstGroup *)burstGroup NS_DESIGNATED_INITIALIZER;

@end
