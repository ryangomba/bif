// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "RGGeometry.h"

CGPoint CGRectGetMidPoint(CGRect rect) {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGSize RGSizeOuterSizeWithAspectRatio(CGSize size, CGFloat aspectRatio) {
    CGFloat targetAspect = size.width / size.height;
    if (aspectRatio == targetAspect) {
        return size;
    }
    
    if (aspectRatio < targetAspect) {
        return CGSizeMake(size.width, size.width / aspectRatio);
    } else {
        return CGSizeMake(size.height * aspectRatio, size.height);
    }
}

CGSize RGSizeInnerSizeWithAspectRatio(CGSize size, CGFloat aspectRatio) {
    CGFloat targetAspect = size.width / size.height;
    if (aspectRatio == targetAspect) {
        return size;
    }
    
    if (aspectRatio > targetAspect) {
        return CGSizeMake(size.width, size.width / aspectRatio);
    } else {
        return CGSizeMake(size.height, size.height * aspectRatio);
    }
}

CGRect RGRectOuterRectWithAspectRatio(CGRect rect, CGFloat aspectRatio) {
    CGSize newSize = RGSizeOuterSizeWithAspectRatio(rect.size, aspectRatio);
    
    CGRect outputRect = CGRectZero;
    outputRect.size = newSize;
    outputRect.origin.x = rect.origin.x - (CGFloat)floor((outputRect.size.width - rect.size.width) / 2.0);
    outputRect.origin.y = rect.origin.y - (CGFloat)floor((outputRect.size.height - rect.size.height) / 2.0);
    
    return outputRect;
}

CGRect RGRectInnerRectWithAspectRatio(CGRect rect, CGFloat aspectRatio) {
    CGSize newSize = RGSizeInnerSizeWithAspectRatio(rect.size, aspectRatio);
    
    CGRect outputRect = CGRectZero;
    outputRect.size = newSize;
    outputRect.origin.x = rect.origin.x - (CGFloat)floor((outputRect.size.width - rect.size.width) / 2.0);
    outputRect.origin.y = rect.origin.y - (CGFloat)floor((outputRect.size.height - rect.size.height) / 2.0);
    
    return outputRect;
}
