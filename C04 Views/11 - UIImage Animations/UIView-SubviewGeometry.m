/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import "UIView-SubviewGeometry.h"
static BOOL seeded = NO;

// 此函式是我一個UIView關於frame類目裡的功能
// 我抄來放在這裡，就不需要加入其他檔案了
CGRect CGRectWithCenter(CGRect rect, CGPoint center)
{
	CGRect newrect = CGRectZero;
	newrect.origin.x = center.x-CGRectGetMidX(rect);
	newrect.origin.y = center.y-CGRectGetMidY(rect);
	newrect.size = rect.size;
	return newrect;
}

@implementation UIView (SubviewGeometry)
#pragma mark Bounded Placement
- (BOOL) canMoveToCenter: (CGPoint) aCenter inView: (UIView *) aView withInsets: (UIEdgeInsets) insets
{
	CGRect container = UIEdgeInsetsInsetRect(aView.bounds, insets);
	return CGRectContainsRect(container, CGRectWithCenter(self.frame, aCenter));
}

- (BOOL) canMoveToCenter: (CGPoint) aCenter inView: (UIView *) aView withInset: (float) inset
{
	UIEdgeInsets insets = UIEdgeInsetsMake(inset, inset, inset, inset);
	return [self canMoveToCenter:aCenter inView:aView withInsets:insets];
}

- (BOOL) canMoveToCenter: (CGPoint) aCenter inView: (UIView *) aView
{
	return [self canMoveToCenter:aCenter inView:aView withInset:0];
}

#pragma mark Percent Displacement
// 根據百分比例，將視圖移動到該位置
- (CGPoint) centerInView: (UIView *) aView withHorizontalPercent: (float) h withVerticalPercent: (float) v
{
	// 根據UIEdgeInsets移動，然後根據子視圖的大小
	CGRect baseRect = aView.bounds;
	CGRect subRect = CGRectInset(baseRect, self.frame.size.width / 2.0f, self.frame.size.height / 2.0f);
	
	// 回傳水平百分比為h%、垂直百分比為v%的座標
	float px = (float)(h * subRect.size.width);
	float py = (float)(v * subRect.size.height);
	return CGPointMake(px + subRect.origin.x, py + subRect.origin.y);
}

- (CGPoint) centerInSuperviewWithHorizontalPercent: (float) h withVerticalPercent: (float) v
{
	return [self centerInView:self.superview withHorizontalPercent:h withVerticalPercent:v];
}

#pragma mark Random
// 感謝August Joki與manitoba98
- (CGPoint) randomCenterInView: (UIView *) aView withInsets: (UIEdgeInsets) insets
{
    // 亂數種子
    if (!seeded) {seeded = YES; srandom(time(NULL));}
    
	// 根據UIEdgeInsets移動，然後根據子視圖的大小
	CGRect innerRect = UIEdgeInsetsInsetRect([aView bounds], insets);
	CGRect subRect = CGRectInset(innerRect, self.frame.size.width / 2.0f, self.frame.size.height / 2.0f);
	
	// 回傳亂數點座標
	float rx = (float)(random() % (int)floor(subRect.size.width));
	float ry = (float)(random() % (int)floor(subRect.size.height));
	return CGPointMake(rx + subRect.origin.x, ry + subRect.origin.y);
}

- (CGPoint) randomCenterInView: (UIView *) aView withInset: (float) inset
{
	UIEdgeInsets insets = UIEdgeInsetsMake(inset, inset, inset, inset);
	return [self randomCenterInView:aView withInsets:insets];
}

- (void) moveToRandomLocationInView: (UIView *) aView animated: (BOOL) animated
{
	if (!animated)
	{
		self.center = [self randomCenterInView:aView withInset:5];
		return;
	}
	
    [UIView animateWithDuration:0.3f animations:^(void){
         self.center = [self randomCenterInView:aView withInset:5];}];
}

- (void) moveToRandomLocationInSuperviewAnimated: (BOOL) animated
{
	[self moveToRandomLocationInView:self.superview animated:animated];
}

@end

