// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGPieProgressView.h"

CGFloat const kAngleOffset = -90.0f;
CGFloat const kBorderWidth = 1.0;

@implementation BGPieProgressView

#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)aFrame {
    if ((self = [super initWithFrame:aFrame])) {
        self.backgroundColor = [UIColor clearColor];
        
        self.progress = 0.0;
        self.color = [UIColor whiteColor];
    }
    return self;
}


#pragma mark -
#pragma mark Properties

- (void)setProgress:(CGFloat)newProgress {
    _progress = fmaxf(0.0f, fminf(1.0f, newProgress));
    
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    
    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGFloat radius = center.y;
    CGFloat angle = ((360.0f * self.progress) + kAngleOffset) / 180.0 * M_PI;
    CGPoint points[3] = {
        CGPointMake(center.x, 0.0f),
        center,
        CGPointMake(center.x + radius * cosf(angle), center.y + radius * sinf(angle))
    };
    
    [self.color set];

    if (self.progress > 0.0f) {
        CGContextAddLines(context, points, sizeof(points) / sizeof(points[0]));
        CGContextAddArc(context, center.x, center.y, radius, kAngleOffset  / 180.0 * M_PI, angle, false);
        CGContextDrawPath(context, kCGPathEOFill);
    }
    
    CGContextSetLineWidth(context, kBorderWidth);
    CGRect pieInnerRect = CGRectMake(kBorderWidth / 2.0f, kBorderWidth / 2.0f, rect.size.width - kBorderWidth, rect.size.height - kBorderWidth);
    CGContextStrokeEllipseInRect(context, pieInnerRect);
}

@end