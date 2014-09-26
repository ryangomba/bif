// Copyright 2014-present Ryan Gomba. All Rights Reserved.

@interface BGTextElement : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CGRect textRect;
@property (nonatomic, strong) NSDictionary *textAttributes;

@end
