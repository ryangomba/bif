// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGPieProgressView.h"

#import "BIFHelpers.h"

CGFloat const kAngleOffset = -90.0f;
CGFloat const kBorderWidth = 1.0;

@interface BGPieProgressLayer : CALayer

@property (nonatomic, assign) CGFloat progress;

@end

@implementation BGPieProgressLayer

@dynamic progress;

+ (BOOL)needsDisplayForKey:(NSString *)key {
    return [key isEqualToString:@"progress"] || [super needsDisplayForKey:key];
}

- (id)actionForKey:(NSString *) aKey {
    if ([aKey isEqualToString:@"progress"]) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:aKey];
        animation.fromValue = [self.presentationLayer valueForKey:aKey];
        return animation;
    }
    return [super actionForKey:aKey];
}

- (void)drawInContext:(CGContextRef)context {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = center.y;
    CGFloat angle = ((360.0f * self.progress) + kAngleOffset) / 180.0 * M_PI;
    CGPoint points[3] = {
        CGPointMake(center.x, 0.0f),
        center,
        CGPointMake(center.x + radius * cosf(angle), center.y + radius * sinf(angle))
    };
    
    CGContextSetFillColorWithColor(context, HEX_COLOR(0x72daff).CGColor);
    
    if (self.progress > 0.0f) {
        CGContextAddLines(context, points, sizeof(points) / sizeof(points[0]));
        CGContextAddArc(context, center.x, center.y, radius, kAngleOffset  / 180.0 * M_PI, angle, false);
        CGContextDrawPath(context, kCGPathEOFill);
    }
    
    CGContextSetStrokeColorWithColor(context, HEX_COLOR(0x72daff).CGColor);
    
    CGContextSetLineWidth(context, kBorderWidth);
    CGRect pieInnerRect = CGRectMake(kBorderWidth / 2.0f, kBorderWidth / 2.0f, self.bounds.size.width - kBorderWidth, self.bounds.size.height - kBorderWidth);
    CGContextStrokeEllipseInRect(context, pieInnerRect);
    
    [super drawInContext:context];
}

@end

@implementation BGPieProgressView

#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)aFrame {
    if (self = [super initWithFrame:aFrame]) {
        self.backgroundColor = [UIColor clearColor];
        
        self.opaque = NO;
        self.layer.contentsScale = [[UIScreen mainScreen] scale];
        
        self.progress = 0.0;
//        self.color = [UIColor whiteColor];
    }
    return self;
}


#pragma mark -
#pragma mark Class Methods

+ (Class)layerClass {
    return [BGPieProgressLayer class];
}


#pragma mark -
#pragma mark Properties

- (void)setProgress:(CGFloat)progress {
    _progress = fmaxf(0.0f, fminf(1.0f, progress));
    
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [(BGPieProgressLayer *)self.layer setProgress:progress];
        [self.layer setNeedsDisplay];
    } completion:nil];
}

//- (void)setColor:(UIColor *)color {
//    _color = color;
//
//    [self.layer setNeedsDisplay];
//}

@end