@import UIKit;
#import "BGLoopMode.h"
#import "BGBurstPhoto.h"

@class BGBurstPreviewView;
@protocol BGBurstPreviewViewDelegate <NSObject>

- (void)burstPreviewView:(BGBurstPreviewView *)previewView didShowPhoto:(BGBurstPhoto *)photo;
- (void)burstPreviewView:(BGBurstPreviewView *)previewView didChangeCropInfo:(CGRect)cropInfo;

@end

@interface BGBurstPreviewView : UIView

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign) CGFloat framesPerSecond;
@property (nonatomic, assign) LoopMode loopMode;

@property (nonatomic, assign) BOOL animated;

@property (nonatomic, assign) CGRect cropInfo;

@property (nonatomic, weak) id<BGBurstPreviewViewDelegate> delegate;

- (NSArray *)allPhotosInRangeWithLoopModeApplied;

@end
