@import UIKit;

@interface UIImage (Resize)

- (CGImageRef)newCGImageWithCropRect:(CGRect)cropRect;

- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)squareThumbnailImageOfSize:(NSInteger)thumbnailSize;
- (UIImage *)resizedImageThatFillsBounds:(CGSize)bounds;
- (UIImage *)resizedImageThatFitsInBounds:(CGSize)bounds;

+ (CGAffineTransform)transformForImageOfSize:(CGSize)imageSize
                                 orientation:(UIImageOrientation)imageOrientation
                                     newSize:(CGSize)newImageSize;

@end
