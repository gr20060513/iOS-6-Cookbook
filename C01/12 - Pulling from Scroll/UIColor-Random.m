/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */


#import "UIColor-Random.h"
// 回傳亂數顏色的圖像
UIImage *randomBlockImage(CGFloat sideLength, CGFloat inset)
{
	UIGraphicsBeginImageContext(CGSizeMake(sideLength, sideLength));
	CGContextRef context = UIGraphicsGetCurrentContext();
    
	// 繪製背景
	CGRect bounds = CGRectMake(0.0f, 0.0f, sideLength, sideLength);
	CGContextAddRect(context, bounds);
	[[UIColor whiteColor] set];
	CGContextFillPath(context);
	CGContextAddRect(context, bounds);
	[[[UIColor randomColor] colorWithAlphaComponent:0.5f] set];
	CGContextFillPath(context);
    
	// 繪製較亮的前景
	CGContextAddEllipseInRect(context, CGRectInset(bounds, inset, inset));
	[[UIColor randomColor] set];
	CGContextFillPath(context);
    
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}


@implementation UIColor(Random)
+(UIColor *)randomColor
{
    static BOOL seeded = NO;
    if (!seeded) {
        seeded = YES;
        srandom(time(NULL));
    }
	
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}
@end

