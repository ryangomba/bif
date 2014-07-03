//
//  BGTextView.h
//  BIF
//
//  Created by Ryan Gomba on 7/2/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <UIKit/UIKit.h>

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
