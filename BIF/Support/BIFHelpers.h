// TODO remove from here

#define ALPHA_COLOR(rgbValue, alphaValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 \
blue:((float)(rgbValue & 0xFF)) / 255.0 \
alpha:alphaValue]

#define HEX_COLOR(rgbValue) ALPHA_COLOR(rgbValue, 1.0)

#define kBGBackgroundColor HEX_COLOR(0x222222)

#define kBGDefaultPadding 15.0
#define kBGLargePadding 20.0
