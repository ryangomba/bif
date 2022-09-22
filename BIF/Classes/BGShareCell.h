@import UIKit;

typedef NS_ENUM(NSInteger, BGShareCellState) {
    BGShareCellStateNormal,
    BGShareCellStateSharing,
    BGShareCellStateShared,
};

@interface BGShareCell : UICollectionViewCell

@property (nonatomic, assign) BGShareCellState shareState;
@property (nonatomic, assign) CGFloat shareProgress;
@property (nonatomic, strong) NSURL *sharedURL;

@property (nonatomic, copy) NSString *defaultTitle;
@property (nonatomic, copy) NSString *workingTitle;
@property (nonatomic, copy) NSString *successTitle;

- (void)setDefaultTitle:(NSString *)defaultTitle
           workingTitle:(NSString *)workingTitle
           successTitle:(NSString *)successTitle
              imageName:(NSString *)imageName;

@end
