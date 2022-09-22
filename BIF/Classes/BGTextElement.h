@import Foundation;

@interface BGTextElement : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CGRect textRect;
@property (nonatomic, strong) NSDictionary *textAttributes;

@end
