@import UIKit;

@class BGTextView;
@protocol BGTextViewDelegate <NSObject>

- (void)textViewDidChangeSize:(BGTextView *)textView;

@end

@interface BGTextView : UIView

@property (nonatomic, readonly) UITextView *internalTextView;

@property (nonatomic, readonly) CGFloat minPosition;
@property (nonatomic, readonly) CGFloat maxPosition;

@property (nonatomic, weak) id<BGTextViewDelegate> delegate;

@end
